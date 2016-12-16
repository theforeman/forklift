#!/usr/bin/env bash

case $1 in
  worker)
    if [ -n "$2" ]; then
      exec runuser apache \
	-s /bin/bash \
	-c "/usr/bin/celery worker \
	--events --app=pulp.server.async.app \
	--loglevel=INFO \
	-c 1 \
        --umask=18 \
	-n reserved_resource_worker-$2@$WORKER_HOST \
	--logfile=/var/log/pulp/reserved_resource_worker-$2.log"
    else
      echo "The 'worker' role must be assigned a unique number as the second positional argument."
      echo "For example 'worker 1'."
      echo "Exiting"
      exit 1
    fi
    ;;
  beat)
    exec runuser apache -s /bin/bash -c "/usr/bin/celery beat --workdir /var/lib/pulp/celery/ -A pulp.server.async.app -f /var/log/pulp/celerybeat.log -l INFO"
    ;;
  resource_manager)
    exec runuser apache \
      -s /bin/bash \
      -c "/usr/bin/celery worker -c 1 -n resource_manager@$WORKER_HOST \
          --events --app=pulp.server.async.app \
          --umask=18 \
          --loglevel=INFO -Q resource_manager \
          --logfile=/var/log/pulp/resource_manager.log"
    ;;
  *)
    echo "'$1' is not a supported celery command."
    echo "Use one of the following: worker, beat, resource_manager."
    echo "Exiting"
    exit 1
    ;;
esac

