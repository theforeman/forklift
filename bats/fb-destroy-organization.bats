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
  hammer organization delete --name="${ORGANIZATION}"
}

@test "Delete Import Organization" {
  hammer organization delete --name="${IMPORT_ORG}"
}

@test "Delete Library Import Organization" {
  hammer organization delete --name="${LIBRARY_IMPORT_ORG}"
}
