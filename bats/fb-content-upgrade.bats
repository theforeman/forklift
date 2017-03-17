#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper

setup() {
  tSetOSVersion
}

@test "upload package" {
  wget https://repos.fedorapeople.org/repos/pulp/pulp/demo_repos/test_errata_install/emoticons-0.1-2.noarch.rpm -P /tmp
  hammer -u admin -p changeme repository upload-content --organization="${ORGANIZATION}"\
    --product="${PRODUCT}" --name="${YUM_REPOSITORY}" --path="/tmp/emoticons-0.1-2.noarch.rpm" | grep -q "Successfully uploaded"
}

@test "sync repository" {
  hammer -u admin -p changeme repository synchronize --organization="${ORGANIZATION}" \
    --product="${PRODUCT}" --name="${YUM_REPOSITORY}"
}

@test "upload puppet module" {
  curl -o /tmp/stbenjam-dummy-0.2.0.tar.gz https://forgeapi.puppetlabs.com/v3/files/stbenjam-dummy-0.2.0.tar.gz
  tFileExists /tmp/stbenjam-dummy-0.2.0.tar.gz && hammer -u admin -p changeme repository upload-content \
    --organization="${ORGANIZATION}" --product="${PRODUCT}" --name="${PUPPET_REPOSITORY}" \
    --path="/tmp/stbenjam-dummy-0.2.0.tar.gz" | grep -q "Successfully uploaded"
}

@test "publish content view" {
  hammer -u admin -p changeme content-view publish --organization="${ORGANIZATION}" \
    --name="${CONTENT_VIEW}"
}

@test "promote content view" {
  hammer -u admin -p changeme content-view version promote  --organization="${ORGANIZATION}" \
    --content-view="${CONTENT_VIEW}" --to-lifecycle-environment="${LIFECYCLE_ENVIRONMENT}" --from-lifecycle-environment="Library"
}

@test "register subscription manager" {
  if [ -e "/etc/rhsm/ca/candlepin-local.pem" ]; then
    rpm -e `rpm -qf /etc/rhsm/ca/candlepin-local.pem`
  fi

  rpm -Uvh http://localhost/pub/katello-ca-consumer-latest.noarch.rpm || true
  subscription-manager register --force --org="${ORGANIZATION/ /_}" --activationkey="Test AK" || true
  subscription-manager status | grep -q "Current"
}

@test "check content host is registered" {
  hammer -u admin -p changeme host info --name $(hostname -f)
}

@test "enable content view repo" {
  subscription-manager repos --enable="${ORGANIZATION/ /_}_${PRODUCT/ /_}_${YUM_REPOSITORY/ /_}" | grep -q "is enabled for this system"
}

@test "install katello-agent" {
  tPackageUpgrade katello-agent && tPackageExists katello-agent
}

@test "start katello-agent" {
  service goferd status || service goferd start
}

@test "30 sec of sleep for groggy gofers" {
  sleep 30
}

@test "install package remotely (katello-agent)" {
  # see http://projects.theforeman.org/issues/15089 for bug related to "|| true"
  timeout 300 hammer -u admin -p changeme host package install --host $(hostname -f) \
    --packages emoticons || true
  tPackageExists emoticons
}

@test "install package locally" {
  tPackageInstall lion && tPackageExists lion
}

@test "publish content view" {
  hammer -u admin -p changeme content-view publish --organization="${ORGANIZATION}" \
    --name="${CONTENT_VIEW}"
}

@test "promote content view" {
  hammer -u admin -p changeme content-view version promote  --organization="${ORGANIZATION}" \
    --content-view="${CONTENT_VIEW}" --to-lifecycle-environment="${LIFECYCLE_ENVIRONMENT}" --from-lifecycle-environment="Library"
}

@test "add puppetclass to host" {
  # FIXME: If katello host is subscribed to itself, should it's puppet env also be updated? #7364
  # Skipping because of http://projects.theforeman.org/issues/8244
  skip
  target_env=$(hammer -u admin -p changeme environment list | grep KT_${ORGANIZATION/ /_}_${LIFECYCLE_ENVIRONMENT/ /_}_${CONTENT_VIEW/ /_} | cut -d\| -f1)
  hammer -u admin -p changeme host update --name $(hostname -f) --environment-id=$target_env \
    --puppetclass-ids=1 | grep -q "Host updated"
}

@test "puppet run applies dummy module" {
  skip # because of above
  puppet agent --test && grep -q Lorem /tmp/dummy
}
