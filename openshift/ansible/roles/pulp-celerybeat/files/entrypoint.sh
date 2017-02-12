#!/bin/bash

set -x 

exec runuser apache \
	-s /bin/bash \
	-c "/usr/bin/celery beat \
	--workdir /var/lib/pulp/celery \
	-A pulp.server.async.app \
	-f /var/log/pulp/celerybeat.log \
	-l INFO"
