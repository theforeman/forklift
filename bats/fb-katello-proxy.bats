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

@test "enable lifecycle environment for proxy" {
  hammer capsule content add-lifecycle-environment --id=$PROXY_ID --environment="Library" --organization="${ORGANIZATION}"
}

@test "sync proxy" {
  hammer capsule content synchronize --id=$PROXY_ID
}

@test "content is available from proxy using old /pulp/repos" {
  tCheckPulpYumContent "${PROXY_HOSTNAME}" "pulp/repos" "Library"
}

@test "content is available from proxy using /pulp/content" {
  tSkipIfNotPulp3Only "/pulp/content"
  tCheckPulpYumContent "${PROXY_HOSTNAME}" "pulp/content" "Library"
}
