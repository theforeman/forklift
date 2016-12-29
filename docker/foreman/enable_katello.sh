#!/bin/bash

if [ $ENABLE_KATELLO = "true" ]; then
  bundle exec rake plugin:assets:precompile['katello']
  bundle exec rake plugin:apipie:cache['katello']
fi
