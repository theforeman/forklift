#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper

setup() {
  tSetOSVersion
  CAPSULE_INFO=$(hammer -u admin -p changeme --output json proxy list --search "feature = \"Pulp Node\"")
  CAPSULE_ID=$(echo $CAPSULE_INFO | ruby -e "require 'json'; puts JSON.load(ARGF.read).first['Id']")
  CAPSULE_HOSTNAME=$(echo $CAPSULE_INFO | ruby -e "require 'json'; puts JSON.load(ARGF.read).first['Name']")
}

@test "capsule is registered" {
  hammer -u admin -p changeme proxy info --id $CAPSULE_ID
}

@test "enable lifecycle environment for capsule" {
  hammer -u admin -p changeme proxy content add-lifecycle-environment --id=$CAPSULE_ID --environment="Library" --organization="Default Organization"
}

@test "sync capsule" {
  hammer -u admin -p changeme proxy content synchronize --id=$CAPSULE_ID
}

@test "content is available from capsule" {
  wget http://$CAPSULE_HOSTNAME/pulp/repos/Default_Organization/Library/Test_CV/custom/Test_Product/Zoo/walrus-0.71-1.noarch.rpm -P /tmp
  tFileExists /tmp/walrus-0.71-1.noarch.rpm && tNonZeroFile /tmp/walrus-0.71-1.noarch.rpm
}
