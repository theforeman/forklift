#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper
load fixtures/content

@test "remove subscription manager" {
  # be nice and perform the clean in any case
  cleanSubscriptionManager

  # only remove on non-RHEL as otherwise we can't reinstall it
  if tIsRHEL; then
    skip "don't remove subscription-manager on RHEL"
  fi
  tPackageRemove subscription-manager
}

@test "disable puppet agent to prevent checkin from registering host to another org" {
  systemctl is-active puppet || skip "Puppet is not active"
  systemctl stop puppet
}

@test "delete host if present" {
  hammer host delete --name="${HOSTNAME}" || echo "Could not delete host"
}

@test "register with global registration with activation key" {
  run yum erase -y 'katello-ca-consumer-*'
  echo "rc=${status}"
  echo "${output}"

  organization_info=$(hammer --output json organization info --name "${ORGANIZATION}")
  organization_id=$(echo "${organization_info}" | ruby -e "require 'json'; puts JSON.load(ARGF.read)['Id']")

  if tIsRHEL; then
    ignore_subman_errors=true
  else
    ignore_subman_errors=false
  fi

  curl_command="curl https://admin:changeme@${HOSTNAME}/api/registration_commands -X POST -H 'Content-Type: application/json' -d '{\"activation_key\":\"${ACTIVATION_KEY}\",\"organization_id\":\"${organization_id}\",\"ignore_subman_errors\":\"${ignore_subman_errors}\"}'"
  registration_json=$(eval "${curl_command}")
  echo "${registration_json}"

  registration_command=$(echo "${registration_json}" | ruby -e "require 'json'; puts JSON.load(ARGF.read).fetch('registration_command')")
  eval "${registration_command}"
  # Remove after subscription-manager 1.29.46 is released
  systemctl start rhsmcertd
  tSubscribedProductOrSCA "${PRODUCT}"
}

@test "check content host is registered" {
  hammer host info --name "${HOSTNAME}"
}

@test "enable content view repo" {
  subscription-manager repos --enable="${ORGANIZATION_LABEL}_${PRODUCT_LABEL}_${YUM_REPOSITORY_LABEL}" | grep -q "is enabled for this system"
}

@test "install package locally" {
  run yum -y remove walrus
  tPackageInstall walrus-0.71 && tPackageExists walrus-0.71
}

@test "check available errata" {
  local next_wait_time=0
  until hammer host errata list --host "${HOSTNAME}" | grep 'RHEA-2012:0055'; do
    if [ $next_wait_time -eq 14 ]; then
      # make one last try, also makes the error nice
      hammer host errata list --host "${HOSTNAME}" | grep 'RHEA-2012:0055'
    fi
    sleep $(( next_wait_time++ ))
  done
}

@test "try fetching container content" {
  tPackageExists podman || tPackageInstall podman
  podman login "${HOSTNAME}" -u admin -p changeme
  if tIsVersionNewer "$(tKatelloVersion)" 4.16; then
    CONTAINER_PULL_LABEL=$(echo "${ORGANIZATION_LABEL}/${PRODUCT_LABEL}/${CONTAINER_REPOSITORY_LABEL}"| tr '[:upper:]' '[:lower:]')
  else
    CONTAINER_PULL_LABEL=$(echo "${ORGANIZATION_LABEL}-${PRODUCT_LABEL}-${CONTAINER_REPOSITORY_LABEL}"| tr '[:upper:]' '[:lower:]')
  fi
  podman pull "${HOSTNAME}/${CONTAINER_PULL_LABEL}"
}

@test "cleanup subscription-manager after content tests" {
  cleanSubscriptionManager
}
