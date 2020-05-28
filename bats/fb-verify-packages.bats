#!/usr/bin/env bats
# vim: ft=sh:sw=2:ts=2:et

set -o pipefail

load os_helper
load foreman_helper

@test "verify no old SCL packages" {
  tSetOSVersion
  FOREMAN_VERSION=$(tForemanVersion)

  if tIsRedHatCompatible; then
    if [[ $FOREMAN_VERSION == 2.* ]]; then
      if rpm --query --all | grep --quiet --extended-regexp 'rh-ruby24|tfm-ror51|tfm-ror52'; then
        exit 1
      fi
    fi
  fi
}
