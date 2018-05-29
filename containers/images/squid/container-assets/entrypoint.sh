#!/bin/bash

mkdir -p /var/spool/squid
/usr/sbin/squid -N -f /etc/squid/squid.conf -z

exec "$@"
