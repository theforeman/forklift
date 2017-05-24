#!/bin/bash

set -xe

/usr/bin/wait_on_database_migration.py

/usr/bin/celery worker -c 1 -n resource_manager@$HOSTNAME \
  	--events --app=pulp.server.async.app \
  	--umask=18 \
  	--loglevel=INFO -Q resource_manager \
  	--logfile=/var/log/pulp/resource_manager.log
