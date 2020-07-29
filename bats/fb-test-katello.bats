#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper

@test "check hammer ping" {
  FOREMAN_VERSION=$(tForemanVersion)
  if [ $FOREMAN_VERSION == '1.24' ]; then
    # https://github.com/theforeman/hammer-cli-foreman/pull/394
    # https://github.com/Katello/hammer-cli-katello/pull/596
    skip "Functionality is broken in 1.24"
  fi

  local next_wait_time=0
  until [ "${status:-1}" -eq 0 -o $next_wait_time -eq 12 ]; do
    run hammer ping
    [[ $status -eq 0 ]] || sleep $(( next_wait_time++ ))
  done

  echo "${output}"

  [ $status -eq 0 ]

  # Hammer exits with 0 on failures
  # https://projects.theforeman.org/issues/30496
  [[ $output != *"FAIL"* ]]
}

@test "check service status" {
  foreman-maintain service status
}
