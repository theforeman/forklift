#!/bin/bash

. /opt/rh/rh-ruby24/enable
. /opt/rh/rh-nodejs8/enable

set -e

if [ "$1" = 'init' ]; then

  /usr/bin/wait_on_postgres
  echo $SEED_ADMIN_PASSWORD
  SEED_ADMIN_PASSWORD=$SEED_ADMIN_PASSWORD bundle exec rake db:migrate db:seed
  /usr/bin/create_qpid_queue
fi

if [ "$1" = 'console' ]; then
  echo $SEED_ADMIN_PASSWORD
  exec bin/rails console
fi

if [ "$1" = 'server' ]; then
  exec bin/rails server -b 0.0.0.0
fi

exec "$@"
