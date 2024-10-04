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

@test "push container to katello" {
  tContainerPushSupported
  tPackageExists podman || tPackageInstall podman
  podman login "${HOSTNAME}" -u admin -p changeme
  CONTAINER_PULL_LABEL=$(echo "${ORGANIZATION_LABEL}-${PRODUCT_LABEL}-${CONTAINER_REPOSITORY_LABEL}"| tr '[:upper:]' '[:lower:]')
  CONTAINER_PUSH_LABEL=$(echo "${ORGANIZATION_LABEL}/${PRODUCT_LABEL}/${CONTAINER_REPOSITORY_LABEL}-bats-$(date -u '+%s')"| tr '[:upper:]' '[:lower:]')
  podman push "${HOSTNAME}/${CONTAINER_PULL_LABEL}" "${HOSTNAME}/${CONTAINER_PUSH_LABEL}"
  # Sleep for 5 seconds due to an intermittent issue where pushed content
  # is not immediately searchable via podman search.
  # See https://github.com/theforeman/forklift/pull/1864 for more information.
  sleep 5
  podman search "${HOSTNAME}/" | grep -q "${CONTAINER_PUSH_LABEL}"
}
