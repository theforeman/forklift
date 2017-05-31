#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper

setup() {
  tSetOSVersion
}

@test "check web app is up" {
  curl -sk "https://localhost$URL_PREFIX/users/login" | grep -q login-form
}

@test "wake up puppet agent" {
  source ~/.bashrc
  puppet agent -t -v
}

@test "check web app is still up" {
  curl -sk "https://localhost$URL_PREFIX/users/login" | grep -q login-form
}

@test "check smart proxy is registered" {
  hammer --csv proxy list | grep -q "$(hostname -f)"
}

@test "check host is registered" {
  hammer host info --name "$(hostname -f)"
}

@test "check katello-service status" {
  katello-service status
}

@test "check hammer ping" {
  hammer ping
}
