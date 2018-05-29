#!/bin/bash

set -x

/usr/bin/wait_on_postgres.py
/usr/bin/wait_on_migrations.py

exec "$@"
