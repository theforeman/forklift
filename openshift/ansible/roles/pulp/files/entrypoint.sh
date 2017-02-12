#!/bin/bash 

set -x

/usr/bin/wait_on_mongodb.py

runuser -u apache pulp-manage-db

exec "$@"
