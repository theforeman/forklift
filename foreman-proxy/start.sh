#!/bin/bash

if ! [ -f /etc/puppet/ssl/certs/foreman-proxy.pem ]; then
  puppet agent -t
fi

/usr/src/app/bin/smart-proxy
