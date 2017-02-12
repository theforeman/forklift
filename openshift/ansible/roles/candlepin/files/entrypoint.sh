#!/bin/bash

set -x

/usr/bin/wait_on_postgres.py

/usr/bin/gen-certs

liquibase \
    --driver=org.postgresql.Driver \
    --classpath=/usr/share/java/postgresql-jdbc.jar:/var/lib/tomcat/webapps/candlepin/WEB-INF/classes/ \
    --changeLogFile=db/changelog/changelog-create.xml \
    --url=jdbc:postgresql://$POSTGRES_SERVICE:$POSTGRES_PORT/$POSTGRES_DB \
    --username=$POSTGRES_USER \
    --password=$POSTGRES_PASSWORD \
    migrate \
    -Dcommunity=False

qpid-config -b tcp://${QPID_SERVICE}:${QPID_PORT} exchanges event

if [ ?! != 0 ]; then
  qpid-config -b tcp://${QPID_SERVICE}:${QPID_PORT} add exchange topic event --durable
fi

exec "$@"
