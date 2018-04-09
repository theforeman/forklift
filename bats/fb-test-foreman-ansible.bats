#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

@test "Install ansible plugins" {
        # TODO: requires https://github.com/theforeman/puppet-foreman/pull/636
        # TODO: requires enabling in scenarios
        foreman-installer --enable-foreman-proxy-plugin-ansible --enable-foreman-plugin-ansible --enable-foreman-cli-ansible
}

@test "Run ansible default role" {
        # https://projects.theforeman.org/issues/23188
	hammer --reload-cache job-invocation create --job-template "Ansible Roles - Ansible Default" --search-query "name = $(hostname -f)"
}
