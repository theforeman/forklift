#!/bin/bash

set -x

/usr/bin/wait_on_postgres.py

foreman-rake db:migrate
echo $SEED_ADMIN_PASSWORD
SEED_ADMIN_PASSWORD=$SEED_ADMIN_PASSWORD foreman-rake db:seed
foreman-rake apipie:cache:index

/usr/bin/create_qpid_queue.sh

exec "$@"
