#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail
load os_helper

@test "change hostname" {
  if tPackageExists satellite; then
    scenario=satellite
  else
    scenario=katello
  fi
  NEW_HOSTNAME="${scenario}-$$.example.com"
  ${scenario}-change-hostname --username admin --password changeme --assumeyes ${NEW_HOSTNAME}
  [ "$(hostname -f)" = "${NEW_HOSTNAME}" ]
}
