#!/bin/bash

sudo docker run -d --name "origin"         --privileged --pid=host --net=host         -v /:/rootfs:ro -v /var/run:/var/run:rw -v /sys:/sys -v /var/lib/docker:/var/lib/docker:rw         -v /var/lib/origin/openshift.local.volumes:/var/lib/origin/openshift.local.volumes         openshift/origin start
