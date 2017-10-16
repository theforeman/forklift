#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

@test "check hammer ping" {
  local next_wait_time=0
  until hammer ping; do
    if [ $next_wait_time -eq 12 ]; then
      # make one last try, also makes the error nice
      hammer ping
    fi
    sleep $(( next_wait_time++ ))
  done
}

@test "check katello-service status" {
  katello-service status
}
