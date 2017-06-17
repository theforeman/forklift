#!/bin/bash

set -x

/usr/bin/wait_on_postgres.py

exec "$@"
