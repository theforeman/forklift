#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

@test "run 'uptime' via Remote Execution" {
  hammer job-invocation create --job-template 'Run Command - SSH Default' --inputs 'command=uptime' --search-query "name = $HOSTNAME"
}
