#!/bin/sh
set -xe
type git || yum -y install git || (apt-get update; apt-get -y install git)
if grep -q 6.0 /etc/debian_version ; then
  # Squeeze backports
  echo "deb http://mirror.bytemark.co.uk/debian-backports squeeze-backports main" > /etc/apt/sources.list.d/backports.list
  echo "Package: *\nPin: release a=squeeze-backports\nPin-Priority: 500\n" > /etc/apt/preferences.d/backports
  apt-get update
fi
git clone https://github.com/sstephenson/bats.git && bats/install.sh /usr
/vagrant/bats/install.sh /usr
