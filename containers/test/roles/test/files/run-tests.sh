#!/bin/bash

cd /root/
ansible-playbook bats.yml -i localhost -e foreman_hostname=$FOREMAN_HOSTNAME
bats container.bats
