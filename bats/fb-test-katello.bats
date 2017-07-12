#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

@test "check hammer ping" {
  local next_wait_time=0
  until hammer ping || [ $next_wait_time -eq 12 ]; do
     sleep $(( next_wait_time++ ))
  done
}

@test "check katello-service status" {
  katello-service status
}
