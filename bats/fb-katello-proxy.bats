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

tCheckContentOnProxy() {
  BASE_PATH=$1
  LCE=$2
  URL1="http://${PROXY_HOSTNAME}/${BASE_PATH}/${ORGANIZATION_LABEL}/${LCE}/${CONTENT_VIEW_LABEL}/custom/${PRODUCT_LABEL}/${YUM_REPOSITORY_LABEL}/walrus-0.71-1.noarch.rpm"
  URL2="http://${PROXY_HOSTNAME}/${BASE_PATH}/${ORGANIZATION_LABEL}/${LCE}/${CONTENT_VIEW_LABEL}/custom/${PRODUCT_LABEL}/${YUM_REPOSITORY_LABEL}/Packages/w/walrus-0.71-1.noarch.rpm"
  (cd /tmp; curl -f -L -O $URL1 || curl -f -L -O $URL2)
  tFileExists /tmp/walrus-0.71-1.noarch.rpm && rpm -qp /tmp/walrus-0.71-1.noarch.rpm
  tFileExists /tmp/walrus-0.71-1.noarch.rpm && rm /tmp/walrus-0.71-1.noarch.rpm
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
  tCheckContentOnProxy "pulp/repos" "Library"
}

@test "content is available from proxy using /pulp/content" {
  tSkipIfNotPulp3Only "/pulp/content"
  tCheckContentOnProxy "pulp/content" "Library"
}
