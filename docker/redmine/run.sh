#!/bin/bash

. /etc/profile.d/rvm.sh

cd redmine
bundle
rake db:create
rake generate_secret_token
rake db:migrate
rake redmine:load_default_data

rails s
