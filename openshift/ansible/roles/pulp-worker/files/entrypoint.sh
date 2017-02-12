#!/bin/bash

set -x 

/usr/bin/wait_on_mongodb.py

exec runuser apache \
	-s /bin/bash \
	-c "/usr/bin/celery worker \
	--events --app=pulp.server.async.app \
	--loglevel=INFO \
	-c 1 \
	--umask=18 \
	-n reserved_resource_worker-$(hostname) \
	--logfile=/var/log/pulp/reserved_resource_worker-1.log"
