#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

@test "assert correct Foreman version is installed" {
  [ -n "$FOREMAN_EXPECTED_VERSION" ] || skip "FOREMAN_EXPECTED_VERSION is not set, not asserting"
  # prints and fails if any VERSION files don't match expected version
  ! grep -v -H -x "$FOREMAN_EXPECTED_VERSION" /usr/share/foreman*/VERSION
}

@test "check web app is up" {
  [ `curl -sk "https://localhost$URL_PREFIX/status" | jq .status` == '"ok"' ] 
}

@test "check smart proxy is registered" {
  hammer proxy info --name=$(hostname -f)
}
