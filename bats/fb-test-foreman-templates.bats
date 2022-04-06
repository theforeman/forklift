#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper

@test "export templates to a temp folder" {
  export_dir=$(runuser -u foreman -- mktemp --directory --tmpdir=/usr/share/foreman/tmp/ template-export.XXXXXXXXXX)
  hammer export-templates --dirname / --repo ${export_dir}
}

@test "import templates from git" {
  hammer import-templates --branch develop --repo https://github.com/theforeman/community-templates
}
