# Spin-docker example dockerfile for PostgreSQL
# https://github.com/atbaker/spin-docker | http://www.postgresql.org/

# Use phusion/baseimage as base image
FROM phusion/baseimage:0.9.8

MAINTAINER Andrew T. Baker <andrew@andrewtorkbaker.com>

# Set correct environment variables
ENV HOME /root

# Use the phusion baseimage's insecure key
RUN /usr/sbin/enable_insecure_key

# Install postgres
RUN locale-gen en_US.UTF-8
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main' | tee /etc/apt/sources.list.d/pgdg.list
ADD ACCC4CF8.asc /tmp/ACCC4CF8.asc
RUN apt-key add /tmp/ACCC4CF8.asc
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql-9.3

# Configure postgres
RUN mkdir -p /usr/local/pgsql/data
RUN chown postgres:postgres /usr/local/pgsql/data
RUN su - postgres -c '/usr/lib/postgresql/9.3/bin/initdb -D /usr/local/pgsql/data/'

# Adjust PostgreSQL configuration so that remote connections to the
# database are possible
# VERY INSECURE! Configure your own users for a production app
RUN echo "host all  all    0.0.0.0/0  trust" >> /usr/local/pgsql/data/pg_hba.conf

# And add ``listen_addresses`` to ``/usr/local/pgsql/data/postgresql.conf``
RUN echo "listen_addresses='*'" >> /usr/local/pgsql/data/postgresql.conf

# Add Postgres to runit
RUN mkdir /etc/service/postgres
ADD run_postgres.sh /etc/service/postgres/run
RUN chown root /etc/service/postgres/run

# Add a spin-docker client to report Postgres connection activity to spin-docker
ADD sd_postgres_client.py /opt/sd_client.py
ADD sd_client_crontab /var/spool/cron/crontabs/root
RUN chown root /opt/sd_client.py /var/spool/cron/crontabs/root

# Clean up APT when done
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Spin-docker currently supports exposing port 22 for SSH and
# one additional application port (Postgres runs on 5432)
EXPOSE 22 5432

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]
