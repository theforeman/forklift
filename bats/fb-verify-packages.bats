#!/usr/bin/env bats
# vim: ft=sh:sw=2:ts=2:et

set -o pipefail

load os_helper
load foreman_helper

@test "verify no old SCL packages" {
  tSetOSVersion
  FOREMAN_VERSION=$(tForemanVersion)

  if tIsRedHatCompatible; then
    if [ $FOREMAN_VERSION == '1.20' ]; then
      if [ `yum list installed | grep -q -E 'rh-ruby24|tfm-ror51'` ]; then
        exit 1
      fi
    fi
  fi
}
