#!/bin/bash

if [ $ENABLE_KATELLO = "true" ]; then
  bundle exec rake plugin:assets:precompile['katello']
  bundle exec rake plugin:apipie:cache['katello']
fi

if [ $ENABLE_FOREMAN_DOCKER = "true" ]; then
  bundle exec rake plugin:assets:precompile['foreman_docker']
  bundle exec rake plugin:apipie:cache['foreman_docker']
fi

if [ $ENABLE_FOREMAN_DISCOVERY = "true" ]; then
  bundle exec rake plugin:assets:precompile['foreman_discovery']
  bundle exec rake plugin:apipie:cache['foreman_discovery']
fi

if [ $ENABLE_FOREMAN_REMOTE_EXECUTION = "true" ]; then
  bundle exec rake plugin:assets:precompile['foreman_remote_execution']
  bundle exec rake plugin:apipie:cache['foreman_remote_execution']
fi

if [ $ENABLE_FOREMAN_HOOKS = "true" ]; then
  bundle exec rake plugin:assets:precompile['foreman_hooks']
  bundle exec rake plugin:apipie:cache['foreman_hooks']
fi

if [ $ENABLE_FOREMAN_OPENSCAP = "true" ]; then
  bundle exec rake plugin:assets:precompile['foreman_openscap']
  bundle exec rake plugin:apipie:cache['foreman_openscap']
fi

if [ $ENABLE_FOREMAN_ANSIBLE = "true" ]; then
  bundle exec rake plugin:assets:precompile['foreman_ansible']
  bundle exec rake plugin:apipie:cache['foreman_ansible']
fi
