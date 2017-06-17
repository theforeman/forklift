#!/bin/bash

ansible-container push --push-to oc-cluster --tag latest --username developer --password $(oc whoami -t) --roles-path ../roles
ansible-playbook ansible-deployment/foreman.yml --tags restart
