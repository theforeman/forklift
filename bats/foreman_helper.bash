# vim: ft=sh:sw=2:et

tForemanSetLang() {
  # facter 1.7- fails to parse some values when non-US LANG and others are set
  # see: http://projects.puppetlabs.com/issues/12012
  export LANGUAGE=en_US.UTF-8
  export LANG=en_US.UTF-8
  export LC_ALL=en_US.UTF-8
}

tForemanVersion() {
  (
    if tPackageExists foreman; then
      tPackageVersion foreman
    elif tPackageExists foreman-installer; then
      tPackageVersion foreman-installer
    fi
  ) | cut -d. -f1-2
}

tKatelloVersion() {
  (
    if tPackageExists tfm-rubygem-katello; then
      tPackageVersion tfm-rubygem-katello
    elif tPackageExists rubygem-katello; then
      tPackageVersion rubygem-katello
    fi
  ) | cut -d. -f1-2
}

tSkipIfPulp339() {
  if tPackageExists python3.11-pulpcore; then
    skip "Skipping on Pulpcore 3.39 until https://github.com/pulp/pulpcore/issues/4777 is fixed"
  fi
}

tIsVersionNewer() {
  GIVEN_VERSION="$1"
  WANTED_VERSION="$2"
  [[ $(printf "%s\n%s" "${GIVEN_VERSION}" "${WANTED_VERSION}" | sort --version-sort | tail -n 1) == "${GIVEN_VERSION}" ]]
}

tIsKatelloAgentRemoved() {
  KATELLO_VERSION=$(tKatelloVersion)
  tIsVersionNewer "${KATELLO_VERSION}" 4.10
}

tSkipIfOlderThan43() {
  KATELLO_VERSION=$(tKatelloVersion)
  if ! tIsVersionNewer "${KATELLO_VERSION}" 4.3; then
    skip "Restricting these tests to Katello 4.3+"
  fi
}

tSkipIfNewerThan45() {
  KATELLO_VERSION=$(tKatelloVersion)
  if tIsVersionNewer "${KATELLO_VERSION}" 4.6; then
    skip "Skip if Katello is newer than 4.5"
  fi
}

tIsPulp2() {
  tPackageExists pulp-server
}

tSkipIfNotPulp3Only() {
  if tIsPulp2; then
    skip "${1} is not available in scenarios with Pulp 2"
  fi
}

cleanSubscriptionManager() {
  run subscription-manager unregister
  echo "rc=${status}"
  echo "${output}"
  run subscription-manager clean
  echo "rc=${status}"
  echo "${output}"
}

tHttpGet() {
  URL=$1
  OUTPUT=${2:-/dev/null}
  curl --fail --location --output "${OUTPUT}" "${URL}"
}

tCheckPulpYumContent() {
  CONTENT_SOURCE=$1
  BASE_PATH=$2
  LCE=$3
  RPM_FILE=${4:-walrus-0.71-1.noarch.rpm}
  REPO_LABEL=${5:-${YUM_REPOSITORY_LABEL}}
  TEST_TMP=$(mktemp -d)
  TEST_RPM_FILE="${TEST_TMP}/${RPM_FILE}"
  URL1="http://${CONTENT_SOURCE}/${BASE_PATH}/${ORGANIZATION_LABEL}/${LCE}/${CONTENT_VIEW_LABEL}/custom/${PRODUCT_LABEL}/${REPO_LABEL}/${RPM_FILE}"
  URL2="http://${CONTENT_SOURCE}/${BASE_PATH}/${ORGANIZATION_LABEL}/${LCE}/${CONTENT_VIEW_LABEL}/custom/${PRODUCT_LABEL}/${REPO_LABEL}/Packages/${RPM_FILE:0:1}/${RPM_FILE}"
  tHttpGet $URL1 ${TEST_RPM_FILE} || tHttpGet $URL2 ${TEST_RPM_FILE}
  tFileExists ${TEST_RPM_FILE} && rpm -qp ${TEST_RPM_FILE}
  tFileExists ${TEST_RPM_FILE} && rm ${TEST_RPM_FILE}
}

tHasContentType() {
  CONTENT_TYPE=$1
  HOSTNAME="$(hostname)"
  HAS_CONTENT_TYPE=$(curl "https://${HOSTNAME}:9090/v2/features" --cert /etc/foreman/client_cert.pem --key /etc/foreman/client_key.pem | ruby -e "require 'json'; puts JSON.load(ARGF.read).fetch('pulpcore').fetch('capabilities').include?('${CONTENT_TYPE}')")
  [[ ${HAS_CONTENT_TYPE} = 'true' ]]
}

tSkipUnlessContentType() {
  CONTENT_TYPE=$1

  if ! tHasContentType $CONTENT_TYPE; then
    skip "Content type ${CONTENT_TYPE} is not enabled"
  fi
}

tSubscribedProductOrSCA() {
  PRODUCT="$1"

  run subscription-manager status
  if [[ $output != *"Simple Content Access"* ]]; then
    echo "SCA not enabled, looking for ${PRODUCT} subscription"
    subscription-manager list --consumed | grep "${PRODUCT}"
  else
    echo "SCA enabled, assuming access to ${PRODUCT} is provided"
  fi
}

tForemanMaintainAvailable() {
  FOREMAN_VERSION=$(tForemanVersion)
  if ! tIsVersionNewer "${FOREMAN_VERSION}" 3.4; then
    tIsEL || skip 'foreman_maintain is not available on non-EL before 3.4'
  fi
}

tForemanMaintainInstall() {
  if tIsEL; then
    PACKAGE=rubygem-foreman_maintain
  elif tIsDebianCompatible; then
    PACKAGE=ruby-foreman-maintain
  fi
  tPackageExists $PACKAGE || tPackageInstall $PACKAGE
}

tScenario() {
  basename $(readlink -f /etc/foreman-installer/scenarios.d/last_scenario.yaml) .yaml
}

tWaitForTask() {
  local TASK_LABEL=$1
  local next_wait_time=0
  while [[ $(hammer --no-headers task list --search="label=${TASK_LABEL} state != stopped" | wc -l) -ne 0 ]]; do
    if [[ $next_wait_time -eq 12 ]]; then
      break
    fi
    sleep $(( next_wait_time++ ))
  done
}
