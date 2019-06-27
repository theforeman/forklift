#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper
load fixtures/content

setup() {
  tSetOSVersion
}

@test "Delete an Organization" {
  sleep 20 # to prevent db deadlocks
  hammer organization delete --name="${ORGANIZATION}"
}
