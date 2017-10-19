#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper
load fixtures/content

setup() {
  tSetOSVersion
  PROXY_INFO=$(hammer --output json proxy list --search "feature = \"Pulp Node\"")
  PROXY_ID=$(echo $PROXY_INFO | ruby -e "require 'json'; puts JSON.load(ARGF.read).first['Id']")
  PROXY_HOSTNAME=$(echo $PROXY_INFO | ruby -e "require 'json'; puts JSON.load(ARGF.read).first['Name']")
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

@test "content is available from proxy" {
  URL1="http://${PROXY_HOSTNAME}/pulp/repos/${ORGANIZATION_LABEL}/Library/${CONTENT_VIEW_LABEL}/custom/${PRODUCT_LABEL}/${YUM_REPOSITORY_LABEL}/walrus-0.71-1.noarch.rpm"
  URL2="http://${PROXY_HOSTNAME}/pulp/repos/${ORGANIZATION_LABEL}/Library/${CONTENT_VIEW_LABEL}/custom/${PRODUCT_LABEL}/${YUM_REPOSITORY_LABEL}/Packages/w/walrus-0.71-1.noarch.rpm"
  (cd /tmp; curl -O $URL1 || curl -O $URL2)
  tFileExists /tmp/walrus-0.71-1.noarch.rpm && tNonZeroFile /tmp/walrus-0.71-1.noarch.rpm
}
