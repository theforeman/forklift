#!/bin/bash

set -xe

/usr/bin/wait_on_mongodb.py

runuser -u apache /usr/bin/migrate_database.py

exec "$@"
