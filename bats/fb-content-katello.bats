#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper
load fixtures/content

setup() {
  tSetOSVersion
}

# Ensure we have at least one organization present so that the test organization
# can be deleted at the end
@test "Create an Empty Organization" {
  run hammer organization info --name "Empty Organization"

  if [ $status != 0 ]; then
    hammer organization create --name="Empty Organization" | grep -q "Organization created"
  fi
}

@test "create an Organization" {
  hammer organization create --name="${ORGANIZATION}" | grep -q "Organization created"
}

@test "create a product" {
  hammer product create --organization="${ORGANIZATION}" --name="${PRODUCT}" | grep -q "Product created"
}

@test "create package repository" {
  hammer repository create --organization="${ORGANIZATION}" \
    --product="${PRODUCT}" --content-type="yum" --name "${YUM_REPOSITORY}" \
    --url https://jlsherrill.fedorapeople.org/fake-repos/needed-errata/ | grep -q "Repository created"
}

@test "upload package" {
  wget https://repos.fedorapeople.org/repos/pulp/pulp/demo_repos/test_errata_install/animaniacs-0.1-1.noarch.rpm -P /tmp
  hammer repository upload-content --organization="${ORGANIZATION}"\
    --product="${PRODUCT}" --name="${YUM_REPOSITORY}" --path="/tmp/animaniacs-0.1-1.noarch.rpm" | grep -q "Successfully uploaded"
}

@test "sync repository" {
  hammer repository synchronize --organization="${ORGANIZATION}" \
    --product="${PRODUCT}" --name="${YUM_REPOSITORY}"
}

@test "create puppet repository" {
  hammer repository create --organization="${ORGANIZATION}" \
    --product="${PRODUCT}" --content-type="puppet" --name "${PUPPET_REPOSITORY}" | grep -q "Repository created"
}

@test "upload puppet module" {
  curl -o /tmp/stbenjam-dummy-0.2.0.tar.gz https://forgeapi.puppetlabs.com/v3/files/stbenjam-dummy-0.2.0.tar.gz
  tFileExists /tmp/stbenjam-dummy-0.2.0.tar.gz && hammer repository upload-content \
    --organization="${ORGANIZATION}" --product="${PRODUCT}" --name="${PUPPET_REPOSITORY}" \
    --path="/tmp/stbenjam-dummy-0.2.0.tar.gz" | grep -q "Successfully uploaded"
}

@test "create lifecycle environment" {
  hammer lifecycle-environment create --organization="${ORGANIZATION}" \
    --prior="Library" --name="${LIFECYCLE_ENVIRONMENT}" | grep -q "Environment created"
}

@test "create content view" {
  hammer content-view create --organization="${ORGANIZATION}" \
    --name="${CONTENT_VIEW}" | grep -q "Content view created"
}

@test "add repo to content view" {
  repo_id=$(hammer repository list --organization="${ORGANIZATION}" \
    | grep ${YUM_REPOSITORY} | cut -d\| -f1 | egrep -i '[0-9]+')
  hammer content-view add-repository --organization="${ORGANIZATION}" \
    --name="${CONTENT_VIEW}" --repository-id=$repo_id | grep -q "The repository has been associated"
}

@test "publish content view" {
  hammer content-view publish --organization="${ORGANIZATION}" \
    --name="${CONTENT_VIEW}"
}

@test "promote content view" {
  hammer content-view version promote  --organization="${ORGANIZATION}" \
    --content-view="${CONTENT_VIEW}" --to-lifecycle-environment="${LIFECYCLE_ENVIRONMENT}" --from-lifecycle-environment="Library"
}

@test "create activation key" {
  hammer activation-key create --organization="${ORGANIZATION}" \
    --name="${ACTIVATION_KEY}" --content-view="${CONTENT_VIEW}" --lifecycle-environment="${LIFECYCLE_ENVIRONMENT}" \
    --unlimited-hosts | grep -q "Activation key created"
}

@test "disable auto-attach" {
  hammer activation-key update --organization="${ORGANIZATION}" \
    --name="${ACTIVATION_KEY}" --auto-attach=false
}

@test "add subscription to activation key" {
  sleep 10
  activation_key_id=$(hammer activation-key info --organization="${ORGANIZATION}" \
    --name="${ACTIVATION_KEY}" | grep ID | tr -d ' ' | cut -d':' -f2)
  subscription_id=$(hammer subscription list --organization="${ORGANIZATION}" \
    | grep "${PRODUCT}" | cut -d\| -f1 | tr -d ' ')
  hammer activation-key add-subscription --id=$activation_key_id \
    --subscription-id=$subscription_id | grep -q "Subscription added to activation key"
}

@test "install subscription manager" {
  if tIsRHEL 6; then
    cat > /etc/yum.repos.d/subscription-manager.repo << EOF
[dgoodwin-subscription-manager]
name=Copr repo for subscription-manager owned by dgoodwin
baseurl=https://copr-be.cloud.fedoraproject.org/results/dgoodwin/subscription-manager/epel-${OS_VERSION}-x86_64/
skip_if_unavailable=True
gpgcheck=0
priority=1
enabled=1
EOF
  fi
  tPackageExists subscription-manager || tPackageInstall subscription-manager
}

@test "register subscription manager" {
  if [ -e "/etc/rhsm/ca/candlepin-local.pem" ]; then
    rpm -e `rpm -qf /etc/rhsm/ca/candlepin-local.pem`
  fi

  run yum erase -y 'katello-ca-consumer-*'
  run rpm -Uvh http://localhost/pub/katello-ca-consumer-latest.noarch.rpm
  run subscription-manager register --force --org="${ORGANIZATION_LABEL}" --activationkey="${ACTIVATION_KEY}"
  subscription-manager list --consumed | grep "${PRODUCT}"
}

@test "check content host is registered" {
  hammer host info --name $(hostname -f)
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
  hammer host errata list --host $(hostname -f) | grep 'RHEA-2012:0055'
}

@test "install katello-agent" {
  tPackageInstall katello-agent && tPackageExists katello-agent
}

@test "30 sec of sleep for groggy gofers" {
  sleep 30
}

@test "install package remotely (katello-agent)" {
  # see http://projects.theforeman.org/issues/15089 for bug related to "|| true"
  run yum -y remove gorilla
  timeout 300 hammer host package install --host $(hostname -f) --packages gorilla || true
  tPackageExists gorilla
}

@test "install errata remotely (katello-agent)" {
  # see http://projects.theforeman.org/issues/15089 for bug related to "|| true"
  timeout 300 hammer host errata apply --errata-ids 'RHEA-2012:0055' --host $(hostname -f) || true
  tPackageExists walrus-5.21
}

@test "add puppet module to content view" {
  repo_id=$(hammer repository list --organization="${ORGANIZATION}" \
    | grep Puppet | cut -d\| -f1 | egrep -i '[0-9]+')
  module_id=$(hammer puppet-module list --repository-id=$repo_id | grep dummy | cut -d\| -f1)
  hammer content-view puppet-module add --organization="${ORGANIZATION}" \
    --content-view="${CONTENT_VIEW}" --id=$module_id | grep -q "Puppet module added to content view"
}

@test "publish content view" {
  hammer content-view publish --organization="${ORGANIZATION}" \
    --name="${CONTENT_VIEW}"
}

@test "promote content view" {
  hammer content-view version promote  --organization="${ORGANIZATION}" \
    --content-view="${CONTENT_VIEW}" --to-lifecycle-environment="${LIFECYCLE_ENVIRONMENT}" --from-lifecycle-environment="Library"
}

@test "add puppetclass to host" {
  # FIXME: If katello host is subscribed to itself, should it's puppet env also be updated? #7364
  # Skipping because of http://projects.theforeman.org/issues/8244
  skip
  target_env=$(hammer environment list | grep KT_${ORGANIZATION_LABEL}_${LIFECYCLE_ENVIRONMENT_LABEL}_${CONTENT_VIEW_LABEL} | cut -d\| -f1)
  hammer host update --name $(hostname -f) --environment-id=$target_env \
    --puppetclass-ids=1 | grep -q "Host updated"
}

@test "puppet run applies dummy module" {
  skip # because of above
  puppet agent --test && grep -q Lorem /tmp/dummy
}
