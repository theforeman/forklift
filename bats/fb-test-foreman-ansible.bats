#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

@test "run 'uptime' via Ansible" {
  hammer job-invocation create --job-template 'Run Command - Ansible Default' --inputs 'command=uptime' --search-query "name = $HOSTNAME"
}
