#!/bin/bash

# Add PULP_MAX_TASKS_PER_CHILD environment variable option
# move working directory to /var/cache/pulp

/usr/bin/celery worker \
  --events --app=pulp.server.async.app \
  --loglevel=INFO \
  -c 1 \
  --umask=18 \
  --max-tasks-per-child=0 \
  -n reserved_resource_worker-$(hostname)
