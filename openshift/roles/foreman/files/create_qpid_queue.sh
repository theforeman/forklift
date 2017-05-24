#!/bin/bash

qpid-config -b tcp://${QPID_SERVICE}:${QPID_PORT} queues katello_event_queue

if [ ?! != 0 ]; then
  qpid-config -b tcp://${QPID_SERVICE}:${QPID_PORT} add queue katello_event_queue --durable
fi
