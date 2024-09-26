#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper
load fixtures/content

@test "try fetching container content" {
  tPackageExists podman || tPackageInstall podman
  podman login "${HOSTNAME}" -u admin -p changeme
  CONTAINER_PULL_LABEL=$(echo "${ORGANIZATION_LABEL}-${PRODUCT_LABEL}-${CONTAINER_REPOSITORY_LABEL}"| tr '[:upper:]' '[:lower:]')
  podman pull "${HOSTNAME}/${CONTAINER_PULL_LABEL}"
}
