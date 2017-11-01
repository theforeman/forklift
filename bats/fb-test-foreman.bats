#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

@test "check web app is up" {
  curl -sk "https://localhost$URL_PREFIX/users/login" | grep login-form
}

@test "wake up puppet agent" {
  source ~/.bashrc
  puppet agent -t -v
}

@test "check web app is still up" {
  curl -sk "https://localhost$URL_PREFIX/users/login" | grep login-form
}

@test "check smart proxy is registered" {
  hammer --csv proxy list | grep -q "$(hostname -f)"
}

@test "check host is registered" {
  hammer host info --name "$(hostname -f)"
}
