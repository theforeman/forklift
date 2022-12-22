#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail
load os_helper
load foreman_helper

setup() {
  export ROLE_NAME=theforeman.batstest
}

@test "run 'uptime' via Ansible" {
  hammer job-invocation create --job-template 'Run Command - Ansible Default' --inputs 'command=uptime' --search-query "name = ${HOSTNAME}"
}

@test "import a role" {
  # create a dummy role
  mkdir -p "/etc/ansible/roles/${ROLE_NAME}/tasks"
  echo "- command: uptime" > "/etc/ansible/roles/${ROLE_NAME}/tasks/main.yml"

  # check if smart_proxy_ansible finds it and can import it
  hammer ansible roles fetch --proxy-id 1
  hammer ansible roles sync --proxy-id 1 --role-names "${ROLE_NAME}"

  # sync creates a task, so let's wait for it to complete
  tWaitForTask SyncRolesAndVariables

  hammer --output csv --no-headers ansible roles list --search="name=${ROLE_NAME}" | grep "${ROLE_NAME}"
}

@test "run a role" {
  # assign the role to our system and run it
  hammer host ansible-roles assign --name "${HOSTNAME}" --ansible-roles "${ROLE_NAME}" | grep 'Ansible roles were assigned to the host'
  hammer host ansible-roles play --name "${HOSTNAME}" | grep 'Ansible roles are being played.'

  # wait for the run to actually succeed
  tWaitForTask Actions::RemoteExecution::RunHostsJob

  # check if the callback reported things back to Foreman
  hammer --output csv --no-headers config-report list --search "host=${HOSTNAME} origin=Ansible" | grep "${HOSTNAME}.*Ansible"
}
