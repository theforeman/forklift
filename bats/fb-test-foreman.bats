#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper

@test "assert correct Foreman version is installed" {
  [ -n "$FOREMAN_EXPECTED_VERSION" ] || skip "FOREMAN_EXPECTED_VERSION is not set, not asserting"
  # prints and fails if any VERSION files don't match expected version
  ! grep -v -H -x "$FOREMAN_EXPECTED_VERSION" /usr/share/foreman*/VERSION
}

@test "check web app is up" {
  [ `curl -sk "https://localhost$URL_PREFIX/status" | ruby -e "require 'json'; puts JSON.load(ARGF.read)['status']"` == 'ok' ]
}

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

@test "check smart proxy is registered" {
  hammer proxy info --name=$(hostname -f)
}
