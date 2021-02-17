#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper

@test "ensure no SELinux denials" {
  if tIsRedHatCompatible; then
    run ausearch --message AVC
    echo "$output"
    [ "${status}" -eq 1 ]
  fi
}
