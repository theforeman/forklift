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

tSkipIfOlderThan41() {
  KATELLO_VERSION=$(tKatelloVersion)
  if [[ $KATELLO_VERSION != 4.* || $KATELLO_VERSION == 4.0 ]]; then
    skip "pulpcore import/export tests are not available on Katello versions older than 4.1"
  fi
}

tSkipIfPulp3Only() {
  KATELLO_VERSION=$(tKatelloVersion)
  if [[ $KATELLO_VERSION == 4.* ]]; then
    skip "${1} is not available in scenarios with only Pulp 3"
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

tCheckContentOnProxy() {
  CONTENT_SOURCE=$1
  BASE_PATH=$2
  LCE=$3
  RPM_FILE=walrus-0.71-1.noarch.rpm
  TEST_TMP=$(mktemp -d)
  TEST_RPM_FILE="${TEST_TMP}/${RPM_FILE}"
  URL1="http://${CONTENT_SOURCE}/${BASE_PATH}/${ORGANIZATION_LABEL}/${LCE}/${CONTENT_VIEW_LABEL}/custom/${PRODUCT_LABEL}/${YUM_REPOSITORY_LABEL}/${RPM_FILE}"
  URL2="http://${CONTENT_SOURCE}/${BASE_PATH}/${ORGANIZATION_LABEL}/${LCE}/${CONTENT_VIEW_LABEL}/custom/${PRODUCT_LABEL}/${YUM_REPOSITORY_LABEL}/Packages/${RPM_FILE:0:1}/${RPM_FILE}"
  curl -f -L --output ${TEST_RPM_FILE} $URL1 || curl -f -L --output ${TEST_RPM_FILE} $URL2
  tFileExists ${TEST_RPM_FILE} && rpm -qp ${TEST_RPM_FILE}
  tFileExists ${TEST_RPM_FILE} && rm ${TEST_RPM_FILE}
}
