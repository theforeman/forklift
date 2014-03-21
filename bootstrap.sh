#!/bin/bash --login

setenforce 0

if [ -d $1 ]
then
  cd $1
fi

rpm -q ruby
RETVAL=$?

if [ $RETVAL == 1 ]
then
    yum -y install ruby
fi

if [ -d '/usr/local/rvm' ]
then
    rvm use system
fi

./setup.rb $@
