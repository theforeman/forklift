# vim: ft=sh:sw=2:et

tIsRedHatCompatible() {
  [[ -f /etc/redhat-release ]]
}

tIsCentOSCompatible() {
  [[ -f /etc/centos-release ]]
}

tIsFedoraCompatible() {
  [[ -f /etc/redhat-release && -f /etc/fedora-release ]]
}

tIsDebianCompatible() {
  [[ -f /etc/debian_version ]]
}

tIsUbuntuCompatible() {
  [[ -f /etc/os-release ]] && grep -q ID=ubuntu /etc/os-release
}

tSetOSVersion() {
  if [[ -z "$OS_VERSION" ]]; then
    if tIsFedoraCompatible; then
      OS_VERSION=$(rpm -q --queryformat '%{VERSION}' fedora-release)
    elif tIsRedHatCompatible; then
      _PKG=$(rpm -qa '(redhat|sl|centos|oraclelinux)-release(|-server|-workstation|-client|-computenode)')
      OS_VERSION=$(rpm -q --queryformat '%{VERSION}' $_PKG | grep -o '^[0-9]*')
    elif tIsUbuntuCompatible; then
      tPackageExists lsb-release || tPackageInstall lsb-release
      OS_VERSION=$(. /etc/os-release; echo $VERSION_ID)
      OS_RELEASE=$(lsb_release -cs)
    elif tIsDebianCompatible; then
      tPackageExists lsb-release || tPackageInstall lsb-release
      OS_VERSION=$(cut -d. -f1 /etc/debian_version)
      OS_RELEASE=$(lsb_release -cs)
    fi
  fi
}

tIsFedora() {
  if [ -z "$1" ]; then
    tIsFedoraCompatible
  else
    tSetOSVersion
    tIsFedoraCompatible && [[ "$1" -eq "$OS_VERSION" ]]
  fi
}

tIsRHEL() {
  if [ -z "$1" ]; then
    tIsRedHatCompatible && ! tIsFedoraCompatible
  else
    tSetOSVersion
    tIsRedHatCompatible && [[ "$1" -eq "$OS_VERSION" ]]
  fi
}

tIsDebian() {
  tIsDebianCompatible && ! tIsUbuntuCompatible
}

tIsUbuntu() {
  tIsUbuntuCompatible
}

tPackageAvailable() {
  if tIsRedHatCompatible; then
    yum info "$1" >/dev/null 2>&1
  elif tIsDebianCompatible; then
    apt-cache show "$1" >/dev/null 2>&1
  else
    false # not implemented
  fi
}

tPackageExists() {
  if tIsRedHatCompatible; then
    rpm -q "$1" >/dev/null
  elif tIsDebianCompatible; then
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q '^i'
  else
    false # not implemented
  fi
}

tPackageInstall() {
  if tIsRedHatCompatible; then
    yum -y install $*
  elif tIsDebianCompatible; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install $*
  else
    false # not implemented
  fi
}

tPackageUpgrade() {
  if tIsRedHatCompatible; then
    yum -y upgrade $*
  elif tIsDebianCompatible; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get -y --only-upgrade -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install $*
  else
    false # not implemented
  fi
}

tPackageVersion() {
  if tIsRedHatCompatible; then
    rpm -q --qf "%{VERSION}\n" "$1"
  elif tIsDebianCompatible; then
    dpkg -s "$1" | awk '/^Version:/ { print $2 }'
  else
    false # not implemented
  fi
}

tServiceDisable() {
  if tCommandExists systemctl; then
    systemctl disable "$1"
  else
    if tIsRedHatCompatible; then
      chkconfig "$1" off
    elif tIsDebianCompatible; then
      update-rc.d "$1" disable
    else
      false # not implemented
    fi
  fi
}

tServiceEnable() {
  if tCommandExists systemctl; then
    systemctl enable "$1"
  else
    if tIsRedHatCompatible; then
      chkconfig "$1" on
    elif tIsDebianCompatible; then
      update-rc.d "$1" enable
    else
      false # not implemented
    fi
  fi
}

tServiceStart() {
  if tCommandExists systemctl; then
    systemctl start "$1"
  else
    service "$1" start
  fi
}

tServiceStop() {
  if tCommandExists systemctl; then
    systemctl stop "$1"
  else
    service "$1" stop
  fi
}

tCommandExists() {
  type -p "$1" >/dev/null
}

tFileExists() {
  [[ -f "$1" ]]
}

tRHSubscribeAttach() {
  if tIsRHEL; then
    [[ -z "$RHSM_USER" || -z "$RHSM_PASS" || -z "$RHSM_POOL" ]] && skip "No subscription-manager credentials and pool id"
    tPackageExists subscription-manager || tPackageInstall subscription-manager
    echo $RHSM_USER $RHSM_PASS $RHSM_POOL
    subscription-manager register --username=$RHSM_USER --password=$RHSM_PASS
    subscription-manager attach --pool=$RHSM_POOL
    subscription-manager repos --enable rhel-server-rhscl-$OS_VERSION-rpms --enable rhel-$OS_VERSION-server-optional-rpms
  else
    skip "Not required"
  fi
}

tRHEnableEPEL() {
  tIsRHEL || skip "Not required"
  tSetOSVersion
  tPackageExists epel-release || \
    rpm -Uvh http://dl.fedoraproject.org/pub/epel/epel-release-latest-${OS_VERSION}.noarch.rpm
}

tNonZeroFile() {
  [[ -s "$1" ]]
}
