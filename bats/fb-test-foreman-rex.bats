#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper

@test "run 'uptime' via Remote Execution" {
  FOREMAN_VERSION=$(tForemanVersion)
  if [[ $FOREMAN_VERSION == 2.* || $FOREMAN_VERSION == 3.[012] ]]; then
    job_template='Run Command - SSH Default'
  else
    job_template='Run Command - Script Default'
  fi

  hammer job-invocation create --job-template "${job_template}" --inputs 'command=uptime' --search-query "name = $HOSTNAME"
}
