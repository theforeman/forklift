#!/bin/bash

set -xe

/usr/bin/wait_on_mongodb.py

exec "$@"
