#!/bin/bash

if [[ -z "$1" ]];then
  ansible-container build --roles-path ./roles ../roles --no-cache
else
  ansible-container build --roles-path ./roles ../roles --services $@
fi
