#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper

@test "export templates to a temp folder" {
  # On Debian we don't have /run/foreman/, but it's the easiest place to export things to.
  # So let's create it here now, until https://projects.theforeman.org/issues/32347 is fixed.
  if tIsDebianCompatible; then
    mkdir /run/foreman/
    chown foreman:foreman /run/foreman/
  fi

  export_dir=$(runuser -u foreman -- mktemp --directory --tmpdir=/run/foreman/ template-export.XXXXXXXXXX)
  hammer export-templates --dirname / --repo ${export_dir}
}
