#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper
load fixtures/content

@test "fetch file from file repository" {
  tHttpGet http://$HOSTNAME/pulp/isos/${ORGANIZATION_LABEL}/Library/custom/${PRODUCT_LABEL}/${FILE_REPOSITORY_LABEL}/1.iso
}

@test "content is available from proxy in the Library LCE using old /pulp/repos" {
  tCheckPulpYumContent $HOSTNAME "pulp/repos" "Library"
}

@test "content is available from proxy in the Library LCE using /pulp/content" {
  tSkipIfNotPulp3Only "/pulp/content"
  tCheckPulpYumContent $HOSTNAME "pulp/content" "Library"
}

@test "content is available from proxy in the ${LIFECYCLE_ENVIRONMENT} LCE using old /pulp/repos" {
  tCheckPulpYumContent $HOSTNAME "pulp/repos" "${LIFECYCLE_ENVIRONMENT_LABEL}"
}

@test "content is available from proxy in the ${LIFECYCLE_ENVIRONMENT} LCE using /pulp/content" {
  tSkipIfNotPulp3Only "/pulp/content"
  tCheckPulpYumContent $HOSTNAME "pulp/content" "${LIFECYCLE_ENVIRONMENT_LABEL}"
}
