#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper
load fixtures/content

setup() {
  tSetOSVersion
  HOSTNAME=$(hostname -f)
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
  tHttpGet http://$HOSTNAME/pulp/isos/${ORGANIZATION_LABEL}/Library/custom/${PRODUCT_LABEL}/${FILE_REPOSITORY_LABEL}/1.iso
}

@test "create a container repository" {
  hammer repository create --organization="${ORGANIZATION}" --docker-upstream-name="foreman/busybox-test" --url=https://quay.io/ \
    --product="${PRODUCT}" --content-type="docker" --name "${CONTAINER_REPOSITORY}" | grep -q "Repository created"
}

@test "sync container repository" {
  hammer repository synchronize --organization="${ORGANIZATION}" \
    --product="${PRODUCT}" --name="${CONTAINER_REPOSITORY}"
}

@test "create an ostree repository" {
  if tIsRHEL 7; then
    skip "OSTree content is not applicable on EL 7 systems"
  fi

  tSkipIfOlderThan43
  tSkipUnlessContentType 'ostree'

  hammer repository create --organization="${ORGANIZATION}" --url=https://fixtures.pulpproject.org/ostree/small/ \
    --product="${PRODUCT}" --content-type="ostree" --name "${OSTREE_REPOSITORY}" | grep -q "Repository created"
}

@test "sync ostree repository" {
  if tIsRHEL 7; then
    skip "OSTree content is not applicable on EL 7 systems"
  fi

  tSkipIfOlderThan43
  tSkipUnlessContentType 'ostree'

  hammer repository synchronize --organization="${ORGANIZATION}" \
    --product="${PRODUCT}" --name="${OSTREE_REPOSITORY}"
}

@test "create puppet repository" {
  tSkipIfPulp3Only "Puppet content"

  hammer repository create --organization="${ORGANIZATION}" \
    --product="${PRODUCT}" --content-type="puppet" --name "${PUPPET_REPOSITORY}" | grep -q "Repository created"
}

@test "upload puppet module" {
  tSkipIfPulp3Only "Puppet content"

  curl -o /tmp/stbenjam-dummy-0.2.0.tar.gz https://forgeapi.puppetlabs.com/v3/files/stbenjam-dummy-0.2.0.tar.gz
  tFileExists /tmp/stbenjam-dummy-0.2.0.tar.gz && hammer repository upload-content \
    --organization="${ORGANIZATION}" --product="${PRODUCT}" --name="${PUPPET_REPOSITORY}" \
    --path="/tmp/stbenjam-dummy-0.2.0.tar.gz" | grep -q "Successfully uploaded"
}

@test "upload ostree_ref" {
  if tIsRHEL 7; then
    skip "OSTree content is not applicable on EL 7 systems"
  fi

  tSkipIfOlderThan43
  tSkipUnlessContentType 'ostree'

  wget --no-parent -r https://fixtures.pulpproject.org/ostree/small/
  tDirectoryExists fixtures.pulpproject.org/ostree
  tar --exclude="index.html" -cvf "fixtures_small_repo.tar" -C fixtures.pulpproject.org/ostree "small"
  hammer repository upload-content --organization="${ORGANIZATION}" --product="${PRODUCT}" --name ${OSTREE_REPOSITORY} --content-type ostree_ref \
      --path fixtures_small_repo.tar --ostree-repository-name small
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
    --name="${CONTENT_VIEW}" --repository-id="$repo_id" | grep -q "The repository has been associated"
}

@test "publish content view" {
  hammer content-view publish --organization="${ORGANIZATION}" \
    --name="${CONTENT_VIEW}"
}

@test "promote content view" {
  hammer content-view version promote  --organization="${ORGANIZATION}" \
    --content-view="${CONTENT_VIEW}" --to-lifecycle-environment="${LIFECYCLE_ENVIRONMENT}" --from-lifecycle-environment="Library"
}

@test "export content view version" {
  tSkipIfOlderThan41

  hammer content-export complete version --organization="${ORGANIZATION}" \
    --content-view="${CONTENT_VIEW}" --version="1.0"
  export_version_id=$(hammer --output csv --no-headers content-view version show --version="1.0" --content-view="${CONTENT_VIEW}" --organization="${ORGANIZATION}" \
    --fields=id)
  actual_size=$(du -k "$(hammer --output csv --no-headers content-export list --content-view-version-id=$export_version_id --fields="path")"/*.gz | cut -f 1)

 [ $actual_size -ge 40 ]
}

@test "create skeleton org for import" {
  tSkipIfOlderThan41

  hammer organization create --name="${IMPORT_ORG}" | grep -q "Organization created"
}

@test "import the exported content view" {
  tSkipIfOlderThan41

  latest_export=$(hammer --output csv --no-headers content-export list --content-view "${CONTENT_VIEW}" --organization "${ORGANIZATION}"\
   --content-view-version="1.0" --fields="Id,Path" --per-page=1 --order="id DESC")
  # 16,,/var/lib/pulp/exports/Test_Organization/Test_CV/1.0/2020-12-11T16-04-08-00-00,Test CV 1.0,6,2020-12-11 16:04:12 UTC,2020-12-11 16:04:12 UTC
  export_history_id=$(echo $latest_export | cut -d, -f1) # 16
  export_path=$(echo $latest_export | cut -d, -f2)
  # /var/lib/pulp/exports/Test_Organization/Test_CV/1.0/2020-12-11T16-04-08-00-00
  import_path="/var/lib/pulp/imports/bats-test-$export_history_id"

  mkdir -p $import_path
  cp -r "$export_path"/* $import_path
  chown -R pulp:pulp $import_path

  if [ -f "${export_path}/metadata.json" ]; then
    metadata_path="${export_path}/metadata.json"
  else
    metadata_path="$(pwd)/metadata-$export_history_id.json" # metadata-16.json
  fi
  # no grep here because hammer doesn't output any text on success
  hammer content-import version --organization="${IMPORT_ORG}"\
    --metadata-file="$metadata_path" --path="$import_path"
}

@test "compare contents of export and import" {
  tSkipIfOlderThan41
  export_version=$(hammer --output csv --no-headers content-view version list --content-view="${CONTENT_VIEW}" --organization="${ORGANIZATION}"\
               --per-page=1 --fields="Version"  --order="version DESC")
  hammer --output csv --no-headers content-view version show --content-view="${CONTENT_VIEW}" --organization="${ORGANIZATION}" \
    --version="${export_version}" --fields="Repositories/Name" | tr "," "\n" | sort > export_repos
  hammer --output csv --no-headers content-view version show --content-view="${CONTENT_VIEW}" --organization="${IMPORT_ORG}" \
    --version="${export_version}" --fields="Repositories/Name" | tr "," "\n" | sort > import_repos

  diff import_repos export_repos
}

@test "export the library" {
  tSkipIfOlderThan41

  hammer content-export complete library --organization="${ORGANIZATION}"
  export_version_id=$(hammer --output csv --no-headers content-view version list --content-view="${LIBRARY}" --organization="${ORGANIZATION}" \
    --fields=id --per-page=1 --order="version DESC")
  actual_size=$(du -k "$(hammer --output csv --no-headers content-export list --content-view-version-id=$export_version_id --fields="path")"/*.gz | cut -f 1)

  [ $actual_size -ge 40 ]
}

@test "create org for library import" {
  tSkipIfOlderThan41

  hammer organization create --name="${LIBRARY_IMPORT_ORG}"
}

@test "import the library to the new organization" {
  tSkipIfOlderThan41

  latest_export=$(hammer --output csv --no-headers content-export list --content-view "${LIBRARY}" --organization "${ORGANIZATION}"\
    --fields="Id,Path" --per-page=1 --order="id DESC")
  export_history_id=$(echo $latest_export | cut -d, -f1) # 16
  export_path=$(echo $latest_export | cut -d, -f2)
  # /var/lib/pulp/exports/Test_Organization/Export-Library/1.0/2020-12-11T16-04-08-00-00
  import_path="/var/lib/pulp/imports/bats-test-library-$export_history_id"

  mkdir -p $import_path
  cp -r $export_path/* $import_path
  chown -R pulp:pulp $import_path

  hammer content-import library --organization="${LIBRARY_IMPORT_ORG}" --path="${import_path}"
}

@test "compare contents of library export and import" {
  tSkipIfOlderThan41

  export_version=$(hammer --output csv --no-headers content-view version list --content-view="${LIBRARY}" --organization="${ORGANIZATION}"\
               --per-page=1 --fields="Version"  --order="version DESC")
  hammer --output csv --no-headers content-view version show --content-view="${LIBRARY}" --organization="${ORGANIZATION}" \
    --version="${export_version}" --fields="Repositories/Name" | tr "," "\n" | sort > library_export_repos
  hammer --output csv --no-headers content-view version show --content-view="${IMPORT_LIBRARY}" --organization="${LIBRARY_IMPORT_ORG}" \
    --version="${export_version}" --fields="Repositories/Name" | tr "," "\n" | sort > library_import_repos

  diff library_import_repos library_export_repos
}


@test "publish content view again" {
  hammer content-view publish --organization="${ORGANIZATION}" \
    --name="${CONTENT_VIEW}"
}

@test "perform an incremental export" {
  tSkipIfOlderThan41
  export_version_id=$(hammer --output csv --no-headers content-view version list --content-view="${CONTENT_VIEW}" --organization="${ORGANIZATION}" \
    --fields=id --per-page=1 --order="version DESC")

  hammer content-export incremental version --organization="${ORGANIZATION}" \
    --content-view="${CONTENT_VIEW}" --id="$export_version_id"
  actual_size=$(du -k "$(hammer --output csv --no-headers content-export list --content-view-version-id=$export_version_id --fields="path" --per-page=1)"/*.gz  | cut -f 1)
  # actual size of export should be less than 14K
  [ $actual_size -le 14 ]
}

@test "perform an incremental library export" {
  tSkipIfOlderThan41
  hammer content-export incremental library --organization="${ORGANIZATION}"

  export_version_id=$(hammer --output csv --no-headers content-view version list --content-view="${LIBRARY}" --organization="${ORGANIZATION}" \
    --fields=id --per-page=1 --order="version DESC")

  actual_size=$(du -k "$(hammer --output csv --no-headers content-export list --content-view-version-id=$export_version_id --fields="path"  --per-page=1)"/*.gz | cut -f 1)

  [ $actual_size -le 14 ]
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

@test "add puppet module to content view" {
  tSkipIfPulp3Only "Puppet content"

  repo_id=$(hammer --csv --no-headers repository list --organization="${ORGANIZATION}" \
    | grep Puppet | cut -d, -f1)
  module_id=$(hammer --csv --no-headers puppet-module list --repository-id=$repo_id | grep dummy | cut -d, -f1)
  hammer content-view puppet-module add --organization="${ORGANIZATION}" \
    --content-view="${CONTENT_VIEW}" --id=$module_id | grep -q "Puppet module added to content view"
}

@test "promote first content view again" {
  hammer content-view version promote  --organization="${ORGANIZATION}" \
    --content-view="${CONTENT_VIEW}" --to-lifecycle-environment="${LIFECYCLE_ENVIRONMENT}" --from-lifecycle-environment="Library"
}

# TODO: Move modules-rpms to a more permanent repo https://pulp.plan.io/issues/7333
@test "create and sync modules-rpms repo" {
  hammer repository create --organization="${ORGANIZATION}" \
    --product="${PRODUCT}" --content-type="yum" --name "${YUM_REPOSITORY_2}" \
    --url https://partha.fedorapeople.org/test-repos/separated/modules-rpms/ | grep -q "Repository created"
  hammer repository synchronize --organization="${ORGANIZATION}" \
    --product="${PRODUCT}" --name="${YUM_REPOSITORY_2}"
}

# TODO: Move rpm-deps to a more permanent repo https://pulp.plan.io/issues/7333
@test "create and sync rpm-deps repo" {
  hammer repository create --organization="${ORGANIZATION}" \
    --product="${PRODUCT}" --content-type="yum" --name "${YUM_REPOSITORY_3}" \
    --url https://partha.fedorapeople.org/test-repos/separated/rpm-deps/ | grep -q "Repository created"
  hammer repository synchronize --organization="${ORGANIZATION}" \
    --product="${PRODUCT}" --name="${YUM_REPOSITORY_3}"
}

@test "create first component content view" {
  hammer content-view create --organization="${ORGANIZATION}" \
    --name="${CONTENT_VIEW_2}" | grep -q "Content view created"
}

@test "add yum and docker repos to first component content view" {
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
  hammer content-view filter create --organization="${ORGANIZATION}" \
    --content-view="${CONTENT_VIEW_2}" --name="${FILTER1}" --type=erratum
  hammer content-view filter rule create --organization="${ORGANIZATION}" \
    --content-view="${CONTENT_VIEW_2}" --content-view-filter="${FILTER1}" --errata-id=WALRUS-2013:0002
}

@test "add package exclude filter to first component content view" {
  hammer content-view filter create --organization="${ORGANIZATION}" \
    --content-view="${CONTENT_VIEW_2}" --name="${FILTER2}" --type=rpm
  hammer content-view filter rule create --organization="${ORGANIZATION}" \
    --content-view="${CONTENT_VIEW_2}" --content-view-filter="${FILTER2}" --name="*"
}

@test "add module include filter to first component content view" {
  hammer content-view filter create --organization="${ORGANIZATION}" \
    --content-view="${CONTENT_VIEW_2}" --name="${FILTER3}" --inclusion=true --type=modulemd
  modulemd_id=$(hammer --csv --no-headers module-stream list --organization="${ORGANIZATION}" \
    | grep "5.21" | cut -d, -f1)
  hammer content-view filter rule create --organization="${ORGANIZATION}" \
    --content-view="${CONTENT_VIEW_2}" --content-view-filter="${FILTER3}" --module-stream-ids=$modulemd_id
}

@test "publish first component content view" {
  hammer content-view publish --organization="${ORGANIZATION}" \
    --name="${CONTENT_VIEW_2}"
}

@test "create composite content view" {
  cv_id1=$(hammer --csv --no-headers content-view version list --organization="${ORGANIZATION}" \
    | grep "${CONTENT_VIEW_2} 1.0" | cut -d, -f1)
  cv_id2=$(hammer --csv --no-headers content-view version list --organization="${ORGANIZATION}" \
    | grep "${CONTENT_VIEW} 2.0" | cut -d, -f1)
  hammer content-view create --organization="${ORGANIZATION}" \
    --name="${CONTENT_VIEW_3}" --composite --component-ids=$cv_id1,$cv_id2
}

@test "publish and promote composite content view" {
  hammer content-view publish --organization="${ORGANIZATION}" \
    --name="${CONTENT_VIEW_3}"
  hammer content-view version promote --organization="${ORGANIZATION}" \
    --content-view="${CONTENT_VIEW_3}" --to-lifecycle-environment="${LIFECYCLE_ENVIRONMENT}" --from-lifecycle-environment="Library"
}

@test "incremental update first component cv with composite propagation" {
  cvv_id=$(hammer --csv --no-headers content-view version list --organization="${ORGANIZATION}" \
    | grep "${CONTENT_VIEW_2}" | cut -d, -f1)
  hammer content-view version incremental-update --organization="${ORGANIZATION}" \
    --content-view-version-id=$cvv_id --errata-ids=WALRUS-2013:0002 --propagate-all-composites=true \
    --lifecycle-environments="Library"
}

@test "ensure component cv 1 version 1.1 has proper environments" {
  cvv_id=$(hammer --csv --no-headers content-view version list --organization="${ORGANIZATION}" \
    | grep "${CONTENT_VIEW_2} 1.1" | cut -d, -f1)
  envs_found=$(hammer content-view version info --organization="${ORGANIZATION}" \
    --id=$cvv_id | awk '/Lifecycle Environments/{flag=1;next}/Repositories/{flag=0}flag' | grep "Name:")
  echo $envs_found | grep -q -E "Name:\s+Library"
}

@test "ensure composite cv version 1.1 has proper environments" {
  cvv_id=$(hammer --csv --no-headers content-view version list --organization="${ORGANIZATION}" \
    | grep "${CONTENT_VIEW_3} 1.1" | cut -d, -f1)
  envs_found=$(hammer content-view version info --organization="${ORGANIZATION}" \
    --id=$cvv_id | awk '/Lifecycle Environments/{flag=1;next}/Repositories/{flag=0}flag' | grep "Name:")
  echo $envs_found | grep -q -E "Name:\s+Library"
  echo $envs_found | grep -q -E "Name:\s+${LIFECYCLE_ENVIRONMENT}"
}

@test "ensure component cv 1 latest version has proper content" {
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
    --order='tag' | grep 'sha256:13280b5914050853a87d662c3229d42b61544e36dd4515f06e188835f3407468'
}

@test "ensure component cv 2 latest version has proper content" {
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
    --order='tag' | grep 'sha256:13280b5914050853a87d662c3229d42b61544e36dd4515f06e188835f3407468'
}

@test "fetch rpm from yum repository on old path" {
  tCheckPulpYumContent "${HOSTNAME}" "pulp/repos" "Library"
}
