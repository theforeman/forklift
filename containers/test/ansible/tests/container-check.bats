#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper

setup() {
  tSetOSVersion
}

@test "check web app is up" {
  curl -sk "https://$FOREMAN_HOSTNAME/users/login" | grep -q login-form
}

@test "check hammer ping" {
  hammer ping
}
