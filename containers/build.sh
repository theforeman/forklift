#!/bin/bash

if [[ -z "$1" ]];then
  ansible-container build --roles-path ../roles
else
  ansible-container build --roles-path ../roles --services $@
fi
