#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

@test "check web app is up" {
  curl -sk "https://localhost$URL_PREFIX/users/login" | grep login-form
}

@test "check smart proxy is registered" {
  hammer proxy info --name=$(hostname -f)
}
