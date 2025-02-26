#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper
load fixtures/content

@test "enable remote execution" {
  foreman-installer --enable-foreman-plugin-remote-execution --enable-foreman-proxy-plugin-remote-execution-script --foreman-proxy-plugin-remote-execution-script-install-key=true
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
  # Remove after subscription-manager 1.29.46 is released
  systemctl start rhsmcertd
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

@test "install package remotely" {
  run yum -y remove walrus-0.71
  timeout 300 hammer job-invocation create --feature katello_package_install --inputs 'package=walrus-0.71' --search-query "name = ${HOSTNAME}"
  tPackageExists walrus-0.71
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

@test "install errata remotely" {
  timeout 300 hammer job-invocation create --feature katello_errata_install --inputs 'errata=RHEA-2012:0055' --search-query "name = ${HOSTNAME}"
  tPackageExists walrus-5.21
}

@test "remove package remotely" {
  timeout 300 hammer job-invocation create --feature katello_package_remove --inputs 'package=walrus' --search-query "name = ${HOSTNAME}"
}

@test "clean up subscription-manager after content tests" {
  cleanSubscriptionManager
}
