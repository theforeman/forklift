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

tIsPulp2() {
  tPackageExists pulp-server
}

tSkipIfNoPulp2() {
  if ! tIsPulp2; then
   skip "${1} is not available in scenarios without Pulp 2"
  fi
}

tSkipIfHammerBelow018() {
  if tPackageExists tfm-rubygem-hammer_cli; then
    RPM_PACKAGE=tfm-rubygem-hammer_cli
  else
    RPM_PACKAGE=rubygem-hammer_cli
  fi
  RPM_VERSION=$(rpm -q --queryformat '%{VERSION}' ${RPM_PACKAGE})

  run rpmdev-vercmp $RPM_VERSION 0.18 > /dev/null
  if [[ $status == 12 ]]; then
   skip "Advanced content view tests are not available without hammer-cli >= 0.18"
  fi
}
