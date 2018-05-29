#!/bin/bash

/usr/bin/wait_on_database_migration.py

exec "$@"
