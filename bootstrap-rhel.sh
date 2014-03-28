#!/bin/bash

# Clean out any previous runs
rpm -e epel-release
rpm -e foreman-release
rpm -e katello-repos
rm -f /etc/yum.repos.d/scl.repo

if [ -f /etc/pki/consumer/cert.pem ]
then
  echo "Already registered to customer portal."
  # Try to grab required entitlements in case anything is missing:
  subscription-manager attach --auto
else
  echo "Registering to customer portal..."
  # User will be prompted for username/password:
  subscription-manager register --force --autosubscribe
fi

# Setup RHEL specific repos
yum -y  --disablerepo="*" --enablerepo=rhel-6-server-rpms install yum-utils wget
yum repolist
yum-config-manager --disable "*"
yum-config-manager --enable rhel-6-server-rpms epel
yum-config-manager --enable rhel-6-server-optional-rpms
yum-config-manager --enable rhel-server-rhscl-6-rpms

./bootstrap.sh rhel $@
