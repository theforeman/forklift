#!/bin/bash

set -x

/usr/bin/wait_on_postgres.py

/usr/bin/gen-certs

/usr/share/candlepin/cpdb --create \
                          --schema-only \
                          --dbhost=$POSTGRES_SERVICE \
                          --dbport=$POSTGRES_PORT \
                          --database=$POSTGRES_DB \
                          --user=$POSTGRES_USER  \
                          --password=$POSTGRES_PASSWORD

qpid-config -b tcp://${QPID_SERVICE}:${QPID_PORT} exchanges event

if [ ?! != 0 ]; then
  qpid-config -b tcp://${QPID_SERVICE}:${QPID_PORT} add exchange topic event --durable
fi

exec "$@"
