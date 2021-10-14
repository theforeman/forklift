#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper
load fixtures/content

setup() {
  tSetOSVersion
  PROXY_ID=2
  PROXY_INFO=$(hammer --output json proxy info --id $PROXY_ID)
  PROXY_HOSTNAME=$(echo $PROXY_INFO | ruby -e "require 'json'; puts JSON.load(ARGF.read)['Name']")
}

@test "proxy is registered" {
  hammer proxy info --id $PROXY_ID
}

@test "enable Library lifecycle environment for proxy" {
  hammer capsule content add-lifecycle-environment --id=$PROXY_ID --environment="Library" --organization="${ORGANIZATION}"
}

@test "enable ${LIFECYCLE_ENVIRONMENT} lifecycle environment for proxy"
  hammer capsule content add-lifecycle-environment --id=$PROXY_ID --environment="${LIFECYCLE_ENVIRONMENT}" --organization="${ORGANIZATION}"
}

@test "sync proxy" {
  hammer capsule content synchronize --id=$PROXY_ID
}

@test "content is available from proxy in the Library LCE using old /pulp/repos" {
  tCheckPulpYumContent "${PROXY_HOSTNAME}" "pulp/repos" "Library"
}

@test "content is available from proxy in the Library LCE using /pulp/content" {
  tSkipIfNotPulp3Only "/pulp/content"
  tCheckPulpYumContent "${PROXY_HOSTNAME}" "pulp/content" "Library"
}

@test "content is available from proxy in the ${LIFECYCLE_ENVIRONMENT} LCE using old /pulp/repos" {
  tCheckPulpYumContent "${PROXY_HOSTNAME}" "pulp/repos" "${LIFECYCLE_ENVIRONMENT_LABEL}"
}

@test "content is available from proxy in the ${LIFECYCLE_ENVIRONMENT} LCE using /pulp/content" {
  tSkipIfNotPulp3Only "/pulp/content"
  tCheckPulpYumContent "${PROXY_HOSTNAME}" "pulp/content" "${LIFECYCLE_ENVIRONMENT_LABEL}"
}
