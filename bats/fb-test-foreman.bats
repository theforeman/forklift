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

@test "check service status" {
  tForemanMaintainAvailable

  tForemanMaintainInstall

  foreman-maintain service status
}

@test "check web app is up" {
  [ $(curl -sk "https://localhost$URL_PREFIX/status" | ruby -e "require 'json'; puts JSON.load(ARGF.read)['status']") = "ok" ]
}

@test "check hammer ping" {
  tHammerPing
}

@test "check smart proxy is registered" {
  hammer proxy info --name="$(hostname -f)"
}
