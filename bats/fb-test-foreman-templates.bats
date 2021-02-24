#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

@test "export templates to a temp folder" {
  export_dir=$(runuser -u foreman -- mktemp --directory --tmpdir /run/foreman/ template-export.XXXXXXXXXX)
  hammer export-templates --dirname / --repo ${export_dir}
}
