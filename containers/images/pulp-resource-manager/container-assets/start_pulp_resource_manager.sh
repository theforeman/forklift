#!/bin/bash

/usr/bin/celery worker \
    -c 1
    -n resource_manager@$HOSTNAME \
    --events \
    --app=pulp.server.async.app \
    --umask=18 \
    --loglevel=INFO \
    -Q resource_manager
