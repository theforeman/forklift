#!/bin/bash

/usr/bin/celery \
  beat \
  --workdir /var/lib/pulp/celery \
  --app=pulp.server.async.app \
  --loglevel=INFO
