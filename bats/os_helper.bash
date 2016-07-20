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
    tIsRedHatCompatible
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
    apt-get install -y $*
  else
    false # not implemented
  fi
}

tPackageUpgrade() {
  if tIsRedHatCompatible; then
    yum -y upgrade $*
  elif tIsDebianCompatible; then
    apt-get upgrade -y $*
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

tCommandExists() {
  type -p "$1" >/dev/null
}

tFileExists() {
  [[ -f "$1" ]]
}

tNonZeroFile() {
  [[ -s "$1" ]]
}
