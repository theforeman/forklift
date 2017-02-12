#!/bin/bash

set -x 

exec runuser apache \
	-s /bin/bash \
	-c "/usr/bin/celery worker -c 1 -n resource_manager@$HOSTNAME \
  	--events --app=pulp.server.async.app \
  	--umask=18 \
  	--loglevel=INFO -Q resource_manager \
  	--logfile=/var/log/pulp/resource_manager.log"
