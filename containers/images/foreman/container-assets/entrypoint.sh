#!/bin/bash

set -x

/usr/bin/wait_on_postgres.py

ansible-playbook /root/playbooks/create_qpid_queue.yml

foreman-rake db:migrate
echo $SEED_ADMIN_PASSWORD
SEED_ADMIN_PASSWORD=$SEED_ADMIN_PASSWORD foreman-rake db:seed

exec "$@"
