#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper
load fixtures/content

setup() {
  tSetOSVersion
  HOSTNAME=$(hostname -f)
}

@test "download bootstrap script from /pub and register to Satellite" {
  curl -o   /root/bootstrap.py "http://${SERVERNAME}/pub/bootstrap.py"
  chmod u+x /root/bootstrap.py
  python /root/bootstrap.py -s ${SERVERNAME} -o 'Default_Organization' -L 'Default Location' -a My_Activation_Key --hostgroup=My_Hostgroup --skip puppet --skip foreman --force
  echo "rc=${status}"
  echo "${output}"
  yum -y install tracer-common
  echo "rc=${status}"
  echo "${output}"
  }

@test "Move client to get content from Capsule" {
  python /root/bootstrap.py -s ${CAPSULENAME} -o 'Default_Organization' -L 'Default Location' -a My_Activation_Key --hostgroup=My_Hostgroup --skip puppet --skip foreman --force
  echo "rc=${status}"
  echo "${output}"
}
