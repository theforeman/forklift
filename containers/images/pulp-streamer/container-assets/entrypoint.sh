#!/bin/bash

/usr/bin/wait_on_mongodb.py

exec "$@"
