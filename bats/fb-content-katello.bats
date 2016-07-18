#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper

setup() {
  tSetOSVersion
}

@test "create a product" {
  hammer -u admin -p changeme product create --organization="Default Organization" \
    --name="Test Product" | grep -q "Product created"
}

@test "create package repository" {
  hammer -u admin -p changeme repository create --organization="Default Organization" \
    --product="Test Product" --content-type="yum" --name "Zoo" \
    --url https://repos.fedorapeople.org/repos/pulp/pulp/demo_repos/zoo/ | grep -q "Repository created"
}

@test "upload package" {
  wget https://repos.fedorapeople.org/repos/pulp/pulp/demo_repos/test_errata_install/animaniacs-0.1-1.noarch.rpm -P /tmp
  hammer -u admin -p changeme repository upload-content --organization="Default Organization"\
    --product="Test Product" --name="Zoo" --path="/tmp/animaniacs-0.1-1.noarch.rpm" | grep -q "Successfully uploaded"
}

@test "sync repository" {
  hammer -u admin -p changeme repository synchronize --organization="Default Organization" \
    --product="Test Product" --name="Zoo"
}

@test "create puppet repository" {
  hammer -u admin -p changeme repository create --organization="Default Organization" \
    --product="Test Product" --content-type="puppet" --name "Puppet Modules" | grep -q "Repository created"
}

@test "upload puppet module" {
  curl -o /tmp/stbenjam-dummy-0.2.0.tar.gz https://forgeapi.puppetlabs.com/v3/files/stbenjam-dummy-0.2.0.tar.gz
  tFileExists /tmp/stbenjam-dummy-0.2.0.tar.gz && hammer -u admin -p changeme repository upload-content \
    --organization="Default Organization" --product="Test Product" --name="Puppet Modules" \
    --path="/tmp/stbenjam-dummy-0.2.0.tar.gz" | grep -q "Successfully uploaded"
}

@test "create lifecycle environment" {
  hammer -u admin -p changeme lifecycle-environment create --organization="Default Organization" \
    --prior="Library" --name="Test" | grep -q "Environment created"
}

@test "create content view" {
  hammer -u admin -p changeme content-view create --organization="Default Organization" \
    --name="Test CV" | grep -q "Content view created"
}

@test "add repo to content view" {
  repo_id=$(hammer -u admin -p changeme repository list --organization="Default Organization" \
    | grep Zoo | cut -d\| -f1 | egrep -i '[0-9]+')
  hammer -u admin -p changeme content-view add-repository --organization="Default Organization" \
    --name="Test CV" --repository-id=$repo_id | grep -q "The repository has been associated"
}

@test "add puppet module to content view" {
  repo_id=$(hammer -u admin -p changeme repository list --organization="Default Organization" \
    | grep Puppet | cut -d\| -f1 | egrep -i '[0-9]+')
  module_id=$(hammer -u admin -p changeme puppet-module list --repository-id=$repo_id | grep dummy | cut -d\| -f1)
  hammer -u admin -p changeme content-view puppet-module add --organization="Default Organization" \
    --content-view="Test CV" --id=$module_id | grep -q "Puppet module added to content view"
}

@test "publish content view" {
  hammer -u admin -p changeme content-view publish --organization="Default Organization" \
    --name="Test CV"
}

@test "promote content view" {
  hammer -u admin -p changeme content-view version promote  --organization="Default Organization" \
    --content-view="Test CV" --to-lifecycle-environment="Test" --version 1
}

@test "create activation key" {
  hammer -u admin -p changeme activation-key create --organization="Default Organization" \
    --name="Test AK" --content-view="Test CV" --lifecycle-environment="Test" \
    --unlimited-hosts | grep -q "Activation key created"
}

@test "disable auto-attach" {
  hammer -u admin -p changeme activation-key update --organization="Default Organization" \
    --name="Test AK" --auto-attach=false
}

@test "add subscription to activation key" {
  sleep 10
  activation_key_id=$(hammer -u admin -p changeme activation-key info --organization="Default Organization" \
    --name="Test AK" | grep ID | tr -d ' ' | cut -d':' -f2)
  subscription_id=$(hammer -u admin -p changeme subscription list --organization="Default Organization" \
    | grep "Test Product" | cut -d\| -f1 | tr -d ' ')
  hammer -u admin -p changeme activation-key add-subscription --id=$activation_key_id \
    --subscription-id=$subscription_id | grep -q "Subscription added to activation key"
}

@test "install subscription manager" {
  cat > /etc/yum.repos.d/candlepin.repo << EOF
[dgoodwin-subscription-manager]
name=Copr repo for subscription-manager owned by dgoodwin
baseurl=https://copr-be.cloud.fedoraproject.org/results/dgoodwin/subscription-manager/epel-${OS_VERSION}-x86_64/
skip_if_unavailable=True
gpgcheck=0
priority=1
enabled=1
EOF
  # newer subscription-manager requires centos 6.8 yum, which is available in CR repo
  if tIsRHEL 6; then
    tPackageExists centos-release-cr || tPackageInstall centos-release-cr
  fi
  tPackageExists subscription-manager || tPackageInstall subscription-manager
  yum install -y subscription-manager
}

@test "register subscription manager" {
  if [ -e "/etc/rhsm/ca/candlepin-local.pem" ]; then
    rpm -e `rpm -qf /etc/rhsm/ca/candlepin-local.pem`
  fi

  rpm -Uvh http://localhost/pub/katello-ca-consumer-latest.noarch.rpm || true
  subscription-manager register --force --org="Default_Organization" --activationkey="Test AK" || true
  subscription-manager status | grep -q "Current"
}

@test "check content host is registered" {
  hammer -u admin -p changeme host info --name $(hostname -f)
}

@test "enable content view repo" {
  subscription-manager repos --enable="Default_Organization_Test_Product_Zoo" | grep -q "is enabled for this system"
}

@test "install katello-agent" {
  tPackageInstall katello-agent && tPackageExists katello-agent
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
    --packages walrus || true
  tPackageExists walrus
}

@test "install package locally" {
  tPackageInstall lion && tPackageExists lion
}

@test "add puppetclass to host" {
  # FIXME: If katello host is subscribed to itself, should it's puppet env also be updated? #7364
  # Skipping because of http://projects.theforeman.org/issues/8244
  skip
  target_env=$(hammer -u admin -p changeme environment list | grep KT_Default_Organization_Test_Test_CV | cut -d\| -f1)
  hammer -u admin -p changeme host update --name $(hostname -f) --environment-id=$target_env \
    --puppetclass-ids=1 | grep -q "Host updated"
}

@test "puppet run applies dummy module" {
  skip # because of above
  puppet agent --test && grep -q Lorem /tmp/dummy
}
