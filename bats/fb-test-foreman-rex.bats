#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper

@test "run 'uptime' via Remote Execution" {
  job_template='Run Command - Script Default'

  SMART_PROXY_NAME=$(hostname -f)

  # Force execution of the test in an own Organization
  # This ensures any *other* proxy with the REX capability is not used,
  # as that can lead to wrong results.
  OLD_ORGS=$(hammer --output csv --no-headers --show-ids proxy info --name "${SMART_PROXY_NAME}" --fields Organizations)
  REX_ORG="Remote Execution Org $$"
  hammer organization create --name "${REX_ORG}"
  hammer host update --name "${SMART_PROXY_NAME}" --new-organization "${REX_ORG}"
  hammer proxy update --name "${SMART_PROXY_NAME}" --organizations "${OLD_ORGS},${REX_ORG}"

  hammer job-invocation create --job-template "${job_template}" --inputs 'command=uptime' --search-query "name = $SMART_PROXY_NAME"
}
