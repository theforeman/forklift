#!/bin/bash

/usr/bin/pulp_streamer --nodaemon --syslog --prefix=pulp_streamer --pidfile= --python /usr/share/pulp/wsgi/streamer.tac
