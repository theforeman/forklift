#!/usr/bin/env bash

exec runuser apache \
	-s /bin/bash \
	-c "/usr/bin/celery worker -c 1 -n resource_manager@$WORKER_HOST \
  	--events --app=pulp.server.async.app \
  	--umask=18 \
  	--loglevel=INFO -Q resource_manager \
  	--logfile=/var/log/pulp/resource_manager.log"
