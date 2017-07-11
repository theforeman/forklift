#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

@test "check hammer ping" {
  hammer ping
}

@test "check katello-service status" {
  katello-service status
}
