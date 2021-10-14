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
  RPM_FILE=walrus-0.71-1.noarch.rpm
  TEST_TMP=$(mktemp -d)
  TEST_RPM_FILE="${TEST_TMP}/${RPM_FILE}"
  URL1="http://${PROXY_HOSTNAME}/${BASE_PATH}/${ORGANIZATION_LABEL}/${LCE}/${CONTENT_VIEW_LABEL}/custom/${PRODUCT_LABEL}/${YUM_REPOSITORY_LABEL}/${RPM_FILE}"
  URL2="http://${PROXY_HOSTNAME}/${BASE_PATH}/${ORGANIZATION_LABEL}/${LCE}/${CONTENT_VIEW_LABEL}/custom/${PRODUCT_LABEL}/${YUM_REPOSITORY_LABEL}/Packages/${RPM_FILE:0:1}/${RPM_FILE}"
  curl -f -L --output ${TEST_RPM_FILE} $URL1 || curl -f -L --output ${TEST_RPM_FILE} $URL2
  tFileExists ${TEST_RPM_FILE} && rpm -qp ${TEST_RPM_FILE}
  tFileExists ${TEST_RPM_FILE} && rm ${TEST_RPM_FILE}
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
