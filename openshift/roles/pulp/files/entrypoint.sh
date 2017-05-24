#!/bin/bash

set -xe

/usr/bin/wait_on_mongodb.py

runuser -u apache pulp-manage-db

exec "$@"
