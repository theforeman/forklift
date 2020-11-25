#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper
load fixtures/content

@test "install subscription manager" {
  tPackageExists subscription-manager || tPackageInstall subscription-manager
}

@test "disable puppet agent to prevent checkin from registering host to another org" {
  systemctl is-active puppet || skip "Puppet is not active"
  systemctl stop puppet
}

@test "delete host if present" {
  hammer host delete --name=$HOSTNAME || echo "Could not delete host"
}

@test "register subscription manager with username and password" {
  if [ -e "/etc/rhsm/ca/candlepin-local.pem" ]; then
    rpm -e `rpm -qf /etc/rhsm/ca/candlepin-local.pem`
  fi

  cleanSubscriptionManager

  run yum erase -y 'katello-ca-consumer-*'
  echo "rc=${status}"
  echo "${output}"
  run rpm -Uvh http://$REGISTRATION_HOSTNAME/pub/katello-ca-consumer-latest.noarch.rpm
  echo "rc=${status}"
  echo "${output}"
  subscription-manager register --force --org="${ORGANIZATION_LABEL}" --username=admin --password=changeme --env=Library
}

@test "register subscription manager with activation key" {
  cleanSubscriptionManager

  run subscription-manager register --force --org="${ORGANIZATION_LABEL}" --activationkey="${ACTIVATION_KEY}"
  echo "rc=${status}"
  echo "${output}"
  subscription-manager list --consumed | grep "${PRODUCT}"
}

@test "start puppet again" {
  systemctl is-enabled puppet || skip "Puppet isn't enabled"
  systemctl start puppet
}

@test "check content host is registered" {
  hammer host info --name $HOSTNAME
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
  until hammer host errata list --host $HOSTNAME | grep 'RHEA-2012:0055'; do
    if [ $next_wait_time -eq 14 ]; then
      # make one last try, also makes the error nice
      hammer host errata list --host $HOSTNAME | grep 'RHEA-2012:0055'
    fi
    sleep $(( next_wait_time++ ))
  done
}

@test "install katello-agent" {
  tSkipIfNoPulp2 "katello-agent support"

  tPackageInstall katello-agent && tPackageExists katello-agent
}

@test "30 sec of sleep for groggy gofers" {
  tSkipIfNoPulp2 "katello-agent support"

  sleep 30
}

@test "install package remotely (katello-agent)" {
  tSkipIfNoPulp2 "katello-agent support"

  # see http://projects.theforeman.org/issues/15089 for bug related to "|| true"
  run yum -y remove gorilla
  timeout 300 hammer host package install --host $HOSTNAME --packages gorilla || true
  tPackageExists gorilla
}

@test "install errata remotely (katello-agent)" {
  tSkipIfNoPulp2 "katello-agent support"

  # see http://projects.theforeman.org/issues/15089 for bug related to "|| true"
  timeout 300 hammer host errata apply --errata-ids 'RHEA-2012:0055' --host $HOSTNAME || true
  tPackageExists walrus-5.21
}

# it seems walrus lingers around making subsequent runs fail, so lets test package removal!
@test "package remove (katello-agent)" {
  tSkipIfNoPulp2 "katello-agent support"

  timeout 300 hammer host package remove --host $HOSTNAME --packages walrus
}

@test "try fetching container content" {
  FOREMAN_VERSION=$(tForemanVersion)
  if [[ $(printf "${FOREMAN_VERSION}\n1.20" | sort --version-sort | tail -n 1) == "1.20" ]] ; then
    skip "docker v2 API is not supported on this version"
  fi
  tPackageExists podman || tPackageInstall podman
  podman login $HOSTNAME -u admin -p changeme
  CONTAINER_PULL_LABEL=`echo "${ORGANIZATION_LABEL}-${PRODUCT_LABEL}-${CONTAINER_REPOSITORY_LABEL}"| tr '[:upper:]' '[:lower:]'`
  podman pull "${HOSTNAME}/${CONTAINER_PULL_LABEL}"
}

@test "cleanup subscription-manager after content tests" {
  cleanSubscriptionManager
}
