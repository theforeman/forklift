#!/bin/bash

usage(){
  echo "Usage: <RH Portal Username> <RH Portal Password> <poolid>"
}

USERNAME=$1
PASSWORD=$2
POOLID=$3

if [ -z $USERNAME ]
then
  usage
  exit 1
fi

if [ -z $PASSWORD ]
then
  usage
  exit 2
fi

if [ -z $POOLID ]
then
  usage
  exit 3
fi


# Clean out any previous runs
rpm -e epel-release
rpm -e foreman-release
rpm -e katello-repos
rm -f /etc/yum.repos.d/scl.repo

subscription-manager register --force --username=$USERNAME --password=$PASSWORD --autosubscribe
subscription-manager subscribe --pool=$POOLID

# Setup RHEL specific repos
yum -y  --disablerepo="*" --enablerepo=rhel-6-server-rpms install yum-utils wget
yum repolist
yum-config-manager --disable "*"
yum-config-manager --enable rhel-6-server-rpms epel
yum-config-manager --enable rhel-6-server-optional-rpms
yum-config-manager --enable rhel-server-rhscl-6-rpms

./bootstrap.sh rhel $@
