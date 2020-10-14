#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper
load fixtures/content

setup() {
  tSetOSVersion
  HOSTNAME=$(hostname -f)

  tCommandExists rpmdev-vercmp || tPackageInstall rpmdevtools
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
  (cd /tmp; curl -O https://repos.fedorapeople.org/repos/pulp/pulp/demo_repos/test_errata_install/animaniacs-0.1-1.noarch.rpm)
  hammer repository upload-content --organization="${ORGANIZATION}"\
    --product="${PRODUCT}" --name="${YUM_REPOSITORY}" --path="/tmp/animaniacs-0.1-1.noarch.rpm" | grep -q "Successfully uploaded"
}

@test "sync repository" {
  hammer repository synchronize --organization="${ORGANIZATION}" \
    --product="${PRODUCT}" --name="${YUM_REPOSITORY}"
}

@test "create a file repository" {
  hammer repository create --organization="${ORGANIZATION}" --url=https://fixtures.pulpproject.org/file/ \
    --product="${PRODUCT}" --content-type="file" --name "${FILE_REPOSITORY}" | grep -q "Repository created"
}

@test "sync file repository" {
  hammer repository synchronize --organization="${ORGANIZATION}" \
    --product="${PRODUCT}" --name="${FILE_REPOSITORY}"
}

@test "fetch file from file repository" {
  curl http://$HOSTNAME/pulp/isos/${ORGANIZATION_LABEL}/Library/custom/${PRODUCT_LABEL}/${REPOSITORY_LABEL}/1.iso > /dev/null
}

@test "create a container repository" {
  hammer repository create --organization="${ORGANIZATION}" --docker-upstream-name="fedora/ssh" --url=https://registry-1.docker.io/ \
    --product="${PRODUCT}" --content-type="docker" --name "${CONTAINER_REPOSITORY}" | grep -q "Repository created"
}

@test "sync container repository" {
  hammer repository synchronize --organization="${ORGANIZATION}" \
    --product="${PRODUCT}" --name="${CONTAINER_REPOSITORY}"
}

@test "create puppet repository" {
  tSkipIfNoPulp2 "Puppet content"

  hammer repository create --organization="${ORGANIZATION}" \
    --product="${PRODUCT}" --content-type="puppet" --name "${PUPPET_REPOSITORY}" | grep -q "Repository created"
}

@test "upload puppet module" {
  tSkipIfNoPulp2 "Puppet content"

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

@test "add yum repo to content view" {
  repo_id=$(hammer --csv --no-headers repository list --organization="${ORGANIZATION}" \
    | grep ${YUM_REPOSITORY} | cut -d, -f1)
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
  activation_key_id=$(hammer --csv --no-headers activation-key info --organization="${ORGANIZATION}" \
    --name="${ACTIVATION_KEY}" | cut -d, -f2)
  subscription_id=$(hammer --csv --no-headers subscription list --organization="${ORGANIZATION}" \
    | grep "${PRODUCT}" | cut -d, -f1)
  hammer activation-key add-subscription --id=$activation_key_id \
    --subscription-id=$subscription_id | grep -q "Subscription added to activation key"
}

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

  run subscription-manager unregister
  echo "rc=${status}"
  echo "${output}"
  run subscription-manager clean
  echo "rc=${status}"
  echo "${output}"
  run yum erase -y 'katello-ca-consumer-*'
  echo "rc=${status}"
  echo "${output}"
  run rpm -Uvh http://localhost/pub/katello-ca-consumer-latest.noarch.rpm
  echo "rc=${status}"
  echo "${output}"
  subscription-manager register --force --org="${ORGANIZATION_LABEL}" --username=admin --password=changeme --env=Library
}

@test "register subscription manager with activation key" {
  run subscription-manager unregister
  echo "rc=${status}"
  echo "${output}"
  run subscription-manager clean
  echo "rc=${status}"
  echo "${output}"
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

@test "add puppet module to content view" {
  tSkipIfNoPulp2 "Puppet content"

  repo_id=$(hammer --csv --no-headers repository list --organization="${ORGANIZATION}" \
    | grep Puppet | cut -d, -f1)
  module_id=$(hammer --csv --no-headers puppet-module list --repository-id=$repo_id | grep dummy | cut -d, -f1)
  hammer content-view puppet-module add --organization="${ORGANIZATION}" \
    --content-view="${CONTENT_VIEW}" --id=$module_id | grep -q "Puppet module added to content view"
}

@test "publish content view with puppet content" {
  tSkipIfNoPulp2 "Puppet content"

  hammer content-view publish --organization="${ORGANIZATION}" \
    --name="${CONTENT_VIEW}"
}

@test "promote content view with puppet content" {
  tSkipIfNoPulp2 "Puppet content"

  hammer content-view version promote  --organization="${ORGANIZATION}" \
    --content-view="${CONTENT_VIEW}" --to-lifecycle-environment="${LIFECYCLE_ENVIRONMENT}" --from-lifecycle-environment="Library"
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

# TODO: Move modules-rpms to a more permanent repo https://pulp.plan.io/issues/7333
@test "create and sync modules-rpms repo" {
  tSkipIfHammerBelow018

  hammer repository create --organization="${ORGANIZATION}" \
    --product="${PRODUCT}" --content-type="yum" --name "${YUM_REPOSITORY_2}" \
    --url https://partha.fedorapeople.org/test-repos/separated/modules-rpms/ | grep -q "Repository created"
  hammer repository synchronize --organization="${ORGANIZATION}" \
    --product="${PRODUCT}" --name="${YUM_REPOSITORY_2}"
}

# TODO: Move rpm-deps to a more permanent repo https://pulp.plan.io/issues/7333
@test "create and sync rpm-deps repo" {
  tSkipIfHammerBelow018

  hammer repository create --organization="${ORGANIZATION}" \
    --product="${PRODUCT}" --content-type="yum" --name "${YUM_REPOSITORY_3}" \
    --url https://partha.fedorapeople.org/test-repos/separated/rpm-deps/ | grep -q "Repository created"
  hammer repository synchronize --organization="${ORGANIZATION}" \
    --product="${PRODUCT}" --name="${YUM_REPOSITORY_3}"
}

@test "create first component content view" {
  tSkipIfHammerBelow018

  hammer content-view create --organization="${ORGANIZATION}" \
    --name="${CONTENT_VIEW_2}" | grep -q "Content view created"
}

@test "add yum and docker repos to first component content view" {
  tSkipIfHammerBelow018

  repo_id=$(hammer --csv --no-headers repository list --organization="${ORGANIZATION}" \
    | grep ${YUM_REPOSITORY} | cut -d, -f1)
  hammer content-view add-repository --organization="${ORGANIZATION}" \
    --name="${CONTENT_VIEW_2}" --repository-id=$repo_id | grep -q "The repository has been associated"
  repo_id=$(hammer --csv --no-headers repository list --organization="${ORGANIZATION}" \
    | grep ${YUM_REPOSITORY_2} | cut -d, -f1)
  hammer content-view add-repository --organization="${ORGANIZATION}" \
    --name="${CONTENT_VIEW_2}" --repository-id=$repo_id | grep -q "The repository has been associated"
  repo_id=$(hammer --csv --no-headers repository list --organization="${ORGANIZATION}" \
    | grep ${YUM_REPOSITORY_3} | cut -d, -f1)
  hammer content-view add-repository --organization="${ORGANIZATION}" \
    --name="${CONTENT_VIEW_2}" --repository-id=$repo_id | grep -q "The repository has been associated"
  repo_id=$(hammer --csv --no-headers repository list --organization="${ORGANIZATION}" \
    | grep ${CONTAINER_REPOSITORY} | cut -d, -f1)
  hammer content-view add-repository --organization="${ORGANIZATION}" \
    --name="${CONTENT_VIEW_2}" --repository-id=$repo_id | grep -q "The repository has been associated"
}

@test "add errata exclude filter to first component content view" {
  tSkipIfHammerBelow018

  hammer content-view filter create --organization="${ORGANIZATION}" \
    --content-view="${CONTENT_VIEW_2}" --name="${FILTER1}" --type=erratum
  hammer content-view filter rule create --organization="${ORGANIZATION}" \
    --content-view="${CONTENT_VIEW_2}" --content-view-filter="${FILTER1}" --errata-id=WALRUS-2013:0002
}

@test "add package exclude filter to first component content view" {
  tSkipIfHammerBelow018

  hammer content-view filter create --organization="${ORGANIZATION}" \
    --content-view="${CONTENT_VIEW_2}" --name="${FILTER2}" --type=rpm
  hammer content-view filter rule create --organization="${ORGANIZATION}" \
    --content-view="${CONTENT_VIEW_2}" --content-view-filter="${FILTER2}" --name="*"
}

@test "add module include filter to first component content view" {
  tSkipIfHammerBelow018

  hammer content-view filter create --organization="${ORGANIZATION}" \
    --content-view="${CONTENT_VIEW_2}" --name="${FILTER3}" --inclusion=true --type=modulemd
  modulemd_id=$(hammer --csv --no-headers module-stream list --organization="${ORGANIZATION}" \
    | grep "5.21" | cut -d, -f1)
  hammer content-view filter rule create --organization="${ORGANIZATION}" \
    --content-view="${CONTENT_VIEW_2}" --content-view-filter="${FILTER3}" --module-stream-ids=$modulemd_id
}

@test "publish first component content view" {
  tSkipIfHammerBelow018

  hammer content-view publish --organization="${ORGANIZATION}" \
    --name="${CONTENT_VIEW_2}"
}

@test "create composite content view" {
  tSkipIfHammerBelow018

  cv_id1=$(hammer --csv --no-headers content-view version list --organization="${ORGANIZATION}" \
    | grep "${CONTENT_VIEW_2} 1.0" | cut -d, -f1)
  cv_id2=$(hammer --csv --no-headers content-view version list --organization="${ORGANIZATION}" \
    | grep "${CONTENT_VIEW} 2.0" | cut -d, -f1)
  hammer content-view create --organization="${ORGANIZATION}" \
    --name="${CONTENT_VIEW_3}" --composite --component-ids=$cv_id1,$cv_id2
}

@test "publish and promote composite content view" {
  tSkipIfHammerBelow018

  hammer content-view publish --organization="${ORGANIZATION}" \
    --name="${CONTENT_VIEW_3}"
  hammer content-view version promote --organization="${ORGANIZATION}" \
    --content-view="${CONTENT_VIEW_3}" --to-lifecycle-environment="${LIFECYCLE_ENVIRONMENT}" --from-lifecycle-environment="Library"
}

@test "incremental update first component cv with composite propagation" {
  tSkipIfHammerBelow018

  cvv_id=$(hammer --csv --no-headers content-view version list --organization="${ORGANIZATION}" \
    | grep "${CONTENT_VIEW_2}" | cut -d, -f1)
  hammer content-view version incremental-update --organization="${ORGANIZATION}" \
    --content-view-version-id=$cvv_id --errata-ids=WALRUS-2013:0002 --propagate-all-composites=true \
    --lifecycle-environments="Library"
}

@test "ensure component cv 1 version 1.1 has proper environments" {
  tSkipIfHammerBelow018

  cvv_id=$(hammer --csv --no-headers content-view version list --organization="${ORGANIZATION}" \
    | grep "${CONTENT_VIEW_2} 1.1" | cut -d, -f1)
  envs_found=$(hammer content-view version info --organization="${ORGANIZATION}" \
    --id=$cvv_id | awk '/Lifecycle Environments/{flag=1;next}/Repositories/{flag=0}flag' | grep "Name:")
  echo $envs_found | grep -q -E "Name:\s+Library"
}

@test "ensure composite cv version 1.1 has proper environments" {
  tSkipIfHammerBelow018

  cvv_id=$(hammer --csv --no-headers content-view version list --organization="${ORGANIZATION}" \
    | grep "${CONTENT_VIEW_3} 1.1" | cut -d, -f1)
  envs_found=$(hammer content-view version info --organization="${ORGANIZATION}" \
    --id=$cvv_id | awk '/Lifecycle Environments/{flag=1;next}/Repositories/{flag=0}flag' | grep "Name:")
  echo $envs_found | grep -q -E "Name:\s+Library"
  echo $envs_found | grep -q -E "Name:\s+${LIFECYCLE_ENVIRONMENT}"
}

@test "ensure component cv 1 latest version has proper content" {
  tSkipIfHammerBelow018

  cvv_id=$(hammer --csv --no-headers content-view version list --organization="${ORGANIZATION}" \
    | grep "${CONTENT_VIEW_2} 1.1" | cut -d, -f1)
  hammer package list --content-view-version-id=$cvv_id --order='name DESC' --fields='filename' > cvv_content
  diff cvv_content fixtures/component_1_rpms

  hammer erratum list --content-view-version-id=$cvv_id --order='id' --fields='Errata ID' > cvv_content
  diff cvv_content fixtures/component_1_errata

  hammer module-stream list --content-view-version-id=$cvv_id --order='stream id' \
    --fields="module stream name,stream,version,architecture,context" > cvv_content
  diff cvv_content fixtures/component_1_modulemds

  hammer docker tag list --content-view-version-id=$cvv_id --fields="tag" --order="name" > cvv_content
  diff cvv_content fixtures/component_1_docker_tags

  # Only checking for the v2 manifest due to Pulp2/Pulp3 differences
  hammer docker manifest list --content-view-version-id=$cvv_id --fields="schema version,digest,tags" \
    --order='tag' | grep 'sha256:a6ecbb1553353a08936f50c275b010388ed1bd6d9d84743c7e8e7468e2acd82e'
}

@test "ensure component cv 2 latest version has proper content" {
  tSkipIfHammerBelow018

  cvv_id=$(hammer --csv --no-headers content-view version list --organization="${ORGANIZATION}" \
    | grep "${CONTENT_VIEW} 2.0" | cut -d, -f1)
  hammer package list --content-view-version-id=$cvv_id --order='name DESC' --fields='filename' > cvv_content
  diff cvv_content fixtures/component_2_rpms

  hammer erratum list --content-view-version-id=$cvv_id --order='id' --fields='Errata ID' > cvv_content
  diff cvv_content fixtures/component_2_errata

  hammer module-stream list --content-view-version-id=$cvv_id --order='stream id' \
    --fields="module stream name,stream,version,architecture,context" > cvv_content
  diff cvv_content fixtures/component_2_modulemds

  hammer docker tag list --content-view-version-id=$cvv_id --fields="tag" --order="name" > cvv_content
  diff cvv_content fixtures/component_2_docker_tags

  hammer docker manifest list --content-view-version-id=$cvv_id --fields="schema version,digest,tags" \
    --order='tag' > cvv_content
  diff cvv_content fixtures/component_2_docker_manifests
}

@test "ensure composite cv latest version has proper content" {
  tSkipIfHammerBelow018

  cvv_id=$(hammer --csv --no-headers content-view version list --organization="${ORGANIZATION}" \
    | grep "${CONTENT_VIEW_3} 1.1" | cut -d, -f1)

  # Sorting and removing duplicates due to Pulp2/Pulp3 differences (https://projects.theforeman.org/issues/30755)
  hammer package list --content-view-version-id=$cvv_id --order='name DESC' --fields='filename' \
    | awk '!seen[$0]++' > cvv_content
  diff -w cvv_content fixtures/composite_rpms

  hammer erratum list --content-view-version-id=$cvv_id --order='id' --fields='Errata ID' > cvv_content
  diff cvv_content fixtures/composite_errata

  hammer module-stream list --content-view-version-id=$cvv_id --order='stream id' \
    --fields="module stream name,stream,version,architecture,context" > cvv_content
  diff cvv_content fixtures/composite_modulemds

  hammer docker tag list --content-view-version-id=$cvv_id --fields="tag" --order="name" > cvv_content
  diff cvv_content fixtures/composite_docker_tags

  # Only checking for the v2 manifest due to Pulp2/Pulp3 differences
  hammer docker manifest list --content-view-version-id=$cvv_id --fields="schema version,digest,tags" \
    --order='tag' | grep 'sha256:a6ecbb1553353a08936f50c275b010388ed1bd6d9d84743c7e8e7468e2acd82e'
}
