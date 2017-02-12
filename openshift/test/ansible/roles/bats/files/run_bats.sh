#!/bin/bash

set -x

cat <<EOT >> /etc/hammer/cli.modules.d/foreman.yml
:foreman:
  # Enable/disable foreman commands
  :enable_module: true

  # Your foreman server address
  :host: http://${FOREMAN_HOSTNAME}/

  # Credentials. You'll be asked for them interactively if you leave them blank here
  :username: 'admin'
  #:password: 'example'
  :use_sessions: false
EOT

bats /root/forklift/bats/fb-content-katello.bats
