#!/bin/sh
set -x
type git || yum -y install git || apt-get -y install git

if [ -d "bats" ]; then 
  rm -rf bats
fi
git clone https://github.com/sstephenson/bats.git && bats/install.sh /usr/local

if [ -d "katello-deploy" ]; then 
  rm -rf katello-deploy
fi

git clone https://github.com/katello/katello-deploy.git -b bats && katello-deploy/bats/install.sh /usr/local
