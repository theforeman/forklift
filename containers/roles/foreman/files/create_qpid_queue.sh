#!/bin/bash

qpid-config -b ${QPID_PORT} queues katello_event_queue

if [ ?! != 0 ]; then
  qpid-config -b ${QPID_PORT} add queue katello_event_queue --durable
fi
