#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

@test "export templates to a temp folder" {
  export_dir=$(mktemp --directory)
  chmod 777 ${export_dir}
  hammer export-templates --dirname / --repo ${export_dir}
}
