#!/bin/bash

#if ! [ -f /etc/puppet/ssl/certs/foreman-proxy.pem ]; then
#  puppet agent -t
#fi

/usr/share/foreman-proxy/bin/smart-proxy
