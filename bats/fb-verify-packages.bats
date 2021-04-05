#!/usr/bin/env bats
# vim: ft=sh:sw=2:ts=2:et

set -o pipefail

load os_helper
load foreman_helper

@test "verify no rh-ruby24, tfm-ror51 or tfm-ror52 SCL packages" {
  tSetOSVersion
  if ! tIsRHEL 7; then
    skip "SCL package checks only applicable on EL 7 systems"
  fi

  FOREMAN_VERSION=$(tForemanVersion)
  if [[ $FOREMAN_VERSION != 2.* ]]; then
    skip "Verification of no rh-ruby24, tfm-ror51 or tfm-ror52 packages only applies to Foreman 2.*"
  fi

  if rpm --query --all | grep --quiet --extended-regexp 'rh-ruby24|tfm-ror51|tfm-ror52'; then
    exit 1
  fi
}

@test "verify no rh-ruby25 SCL packages in Foreman 2.5" {
  tSetOSVersion
  if ! tIsRHEL 7; then
    skip "SCL package checks only applicable on EL 7 systems"
  fi

  FOREMAN_VERSION=$(tForemanVersion)
  if [[ $FOREMAN_VERSION != 2.[5-9]* && $FOREMAN_VERSION != 3.* ]]; then
    skip "Verification of no rh-ruby25 packages only applies to Foreman 2.5+"
  fi

  if rpm --query --all | grep --quiet --extended-regexp 'rh-ruby25'; then
    exit 1
  fi
}
