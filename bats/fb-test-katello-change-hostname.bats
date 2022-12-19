#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail
load os_helper
load foreman_helper

@test "change hostname" {
  scenario=$(tScenario)
  NEW_HOSTNAME="${scenario}-$$.example.com"
  ${scenario}-change-hostname --username admin --password changeme --assumeyes ${NEW_HOSTNAME}
  [ "$(hostname -f)" = "${NEW_HOSTNAME}" ]
}
