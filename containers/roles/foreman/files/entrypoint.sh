#!/bin/bash

set -x

/usr/bin/wait_on_postgres.py

foreman-rake db:migrate
echo $SEED_ADMIN_PASSWORD
SEED_ADMIN_PASSWORD=$SEED_ADMIN_PASSWORD foreman-rake db:seed

/usr/bin/create_qpid_queue.sh

exec "$@"
