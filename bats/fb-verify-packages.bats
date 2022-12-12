#!/usr/bin/env bats
# vim: ft=sh:sw=2:ts=2:et

set -o pipefail

load os_helper
load foreman_helper

@test "verify no rh-ruby24, rh-ruby25, tfm-ror51 or tfm-ror52 SCL packages" {
  if ! tIsEL 7; then
    skip "SCL package checks only applicable on EL 7 systems"
  fi

  if rpm --query --all | grep --quiet --extended-regexp 'rh-ruby24|rh-ruby25|tfm-ror51|tfm-ror52'; then
    exit 1
  fi
}
