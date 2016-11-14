#!/bin/sh
set -x
type git || yum -y install git || apt-get -y install git

if [ -d "bats" ]; then 
  rm -rf bats
fi
git clone https://github.com/sstephenson/bats.git && bats/install.sh /usr/local

if [ -d "forklift" ]; then
  rm -rf forklift
fi

git clone https://github.com/katello/forklift.git && forklift/bats/install.sh /usr/local
