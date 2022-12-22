#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper
load fixtures/content

@test "enable katello-agent" {
  KATELLO_VERSION=$(tKatelloVersion)
  if [[ $KATELLO_VERSION != 4.[1-9]* ]]; then
    skip "Enabling katello-agent explicitly is only available with Katello 4.1+"
  fi
  foreman-installer --foreman-proxy-content-enable-katello-agent true
  foreman-maintain packages unlock -y
}

@test "disable puppet agent to prevent checkin from registering host to another org" {
  systemctl is-active puppet || skip "Puppet is not active"
  systemctl stop puppet
}

@test "delete host if present" {
  hammer host delete --name="${HOSTNAME}" || echo "Could not delete host"
}

@test "register subscription manager with username and password" {
  cleanSubscriptionManager

  run yum erase -y 'katello-ca-consumer-*'
  echo "rc=${status}"
  echo "${output}"
  tPackageInstall http://localhost/pub/katello-ca-consumer-latest.noarch.rpm
  echo "rc=${status}"
  echo "${output}"
  subscription-manager register --force --org="${ORGANIZATION_LABEL}" --username=admin --password=changeme --env=Library
}

@test "register subscription manager with activation key" {
  cleanSubscriptionManager

  run subscription-manager register --force --org="${ORGANIZATION_LABEL}" --activationkey="${ACTIVATION_KEY}"
  echo "rc=${status}"
  echo "${output}"
  tSubscribedProductOrSCA "${PRODUCT}"
}

@test "start puppet again" {
  systemctl is-enabled puppet || skip "Puppet isn't enabled"
  systemctl start puppet
}

@test "check content host is registered" {
  hammer host info --name "${HOSTNAME}"
}

@test "enable content view repo" {
  subscription-manager repos --enable="${ORGANIZATION_LABEL}_${PRODUCT_LABEL}_${YUM_REPOSITORY_LABEL}" | grep -q "is enabled for this system"
}

@test "install katello-host-tools" {
  tPackageInstall katello-host-tools && tPackageExists katello-host-tools
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
  CONTAINER_PULL_LABEL=$(echo "${ORGANIZATION_LABEL}-${PRODUCT_LABEL}-${CONTAINER_REPOSITORY_LABEL}"| tr '[:upper:]' '[:lower:]')
  podman pull "${HOSTNAME}/${CONTAINER_PULL_LABEL}"
}

@test "install katello-agent" {
  tPackageInstall katello-agent && tPackageExists katello-agent
}

@test "30 sec of sleep for groggy gofers" {
  sleep 30
}

@test "install package remotely (katello-agent)" {
  run yum -y remove gorilla
  timeout 300 hammer host package install --host "${HOSTNAME}" --packages gorilla
  tPackageExists gorilla
}

@test "install errata remotely (katello-agent)" {
  timeout 300 hammer host errata apply --errata-ids 'RHEA-2012:0055' --host "${HOSTNAME}"
  tPackageExists walrus-5.21
}

# it seems walrus lingers around making subsequent runs fail, so lets test package removal!
@test "package remove (katello-agent)" {
  timeout 300 hammer host package remove --host "${HOSTNAME}" --packages walrus
}

@test "clean up subscription-manager and gofer after content tests" {
  cleanSubscriptionManager
  tPackageRemove gofer
}
