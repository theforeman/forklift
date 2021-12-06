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

@test "enable ${LIFECYCLE_ENVIRONMENT} lifecycle environment for proxy" {
  hammer capsule content add-lifecycle-environment --id=$PROXY_ID --environment="${LIFECYCLE_ENVIRONMENT}" --organization="${ORGANIZATION}"
}

@test "sync proxy" {
  hammer capsule content synchronize --id=$PROXY_ID
}

@test "setup repositories and publish content view version for auto-proxy-sync test" {
  hammer repository create --organization="${ORGANIZATION}" \
    --product="${PRODUCT}" --content-type="yum" --name "${YUM_REPOSITORY_5}" \
    --url https://fixtures.pulpproject.org/rpm-complex-pkg/ | grep -q "Repository created"
  hammer repository synchronize --organization="${ORGANIZATION}" \
    --product="${PRODUCT}" --name="${YUM_REPOSITORY_5}"
  repo_id=$(hammer --csv --no-headers repository list --organization="${ORGANIZATION}" \
    | grep "${YUM_REPOSITORY_5}" | cut -d, -f1)
  hammer content-view add-repository --organization="${ORGANIZATION}" \
    --name="${CONTENT_VIEW}" --repository-id=$repo_id | grep -q "The repository has been associated"
  hammer content-view publish --organization="${ORGANIZATION}" --name="${CONTENT_VIEW}"
}

@test "auto-synced content is available from proxy in the Library LCE using /pulp/content" {
  local next_wait_time=0

  until tCheckPulpYumContent "${PROXY_HOSTNAME}" "pulp/repos" "Library" "complex-package-2.3.4-5.el8.x86_64.rpm" "${YUM_REPOSITORY_5_LABEL}"; do
    if [ $next_wait_time -eq 14 ]; then
      tCheckPulpYumContent "${PROXY_HOSTNAME}" "pulp/repos" "Library" "complex-package-2.3.4-5.el8.x86_64.rpm" "${YUM_REPOSITORY_5_LABEL}"
    fi
    sleep $(( next_wait_time++ ))
  done
}

@test "sync just one content view to the proxy" {
  tSkipIfOlderThan43

  hammer capsule content synchronize --id=$PROXY_ID --content-view="${CONTENT_VIEW}" --organization="${ORGANIZATION}"
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
