#!/bin/bash

set -xe

/usr/bin/wait_on_database_migration.py

/usr/bin/celery beat \
	--workdir /var/lib/pulp/celery \
	-A pulp.server.async.app \
	-f /var/log/pulp/celerybeat.log \
	-l INFO
