#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper

setup() {
  tForemanSetLang
  tSetOSVersion
  FOREMAN_VERSION=$(tForemanVersion)

  tPackageExists 'wget' || tPackageInstall 'wget'
  tPackageExists 'ruby' || tPackageInstall 'ruby'
  # disable firewall
  if tIsRedHatCompatible; then
    if tFileExists /usr/sbin/firewalld; then
      systemctl stop firewalld; systemctl disable firewalld
    elif tCommandExists systemctl; then
      systemctl stop iptables; systemctl disable iptables
    else
      service iptables stop; chkconfig iptables off
    fi
  fi

  tPackageExists curl || tPackageInstall curl
  if tIsRedHatCompatible; then
    tPackageExists yum-utils || tPackageInstall yum-utils
  fi
}

@test "stop puppet agent (if installed)" {
  tPackageExists "puppet" || skip "Puppet package not installed"
  if tIsRHEL 6; then
    service puppet stop; chkconfig puppet off
  elif tIsFedora; then
    service puppetagent stop; chkconfig puppetagent off
  elif tIsDebianCompatible; then
    service puppet stop
  fi
  true
}

@test "clean after puppet (if installed)" {
  [[ -d /var/lib/puppet/ssl ]] || skip "Puppet not installed, or SSL directory doesn't exist"
  rm -rf /var/lib/puppet/ssl
}

@test "make sure puppet not configured to other pm" {
  egrep -q "server\s*=" /etc/puppet/puppet.conf || skip "Puppet not installed, or 'server' not configured"
  sed -ir "s/^\s*server\s*=.*/server = $(hostname -f)/g" /etc/puppet/puppet.conf
}


@test "run the installer" {
  if [ -e "/vagrant/setup.rb" ]; then
    cd /vagrant
  else
    wget https://raw.githubusercontent.com/Katello/katello-deploy/master/setup.rb
  fi
  ruby setup.rb --install-options="--foreman-admin-password=changeme"
}

@test "run the installer once again" {
  if [ -e "/vagrant/katello-installer" ]; then
    cd /vagrant/katello-installer
    ./bin/katello-installer --no-colors -v
  else
    katello-installer --no-colors -v
  fi
}

@test "wait 10 seconds" {
  sleep 10
}

@test "check web app is up" {
  curl -sk "https://localhost$URL_PREFIX/users/login" | grep -q login-form
}

@test "wake up puppet agent" {
  puppet agent -t -v
}

@test "check web app is still up" {
  curl -sk "https://localhost$URL_PREFIX/users/login" | grep -q login-form
}

@test "install CLI (hammer)" {
  tPackageInstall foreman-cli
}

@test "check smart proxy is registered" {
  count=$(hammer -u admin -p changeme --csv proxy list | wc -l)
  [ $count -gt 1 ]
}

@test "check host is registered" {
  [ x$FOREMAN_VERSION = "x1.3" ] && skip "Only supported on 1.4+"
  hammer -u admin -p changeme host info --name $(hostname -f) | egrep "Last report.*$(date +%Y/%m/%d)"
}

@test "install subscription manager" {
  cat > /etc/yum.repos.d/candlepin.repo << EOF
[subman]
name=An open source entitlement management system.
baseurl=https://repos.fedorapeople.org/repos/candlepin/subscription-manager/epel-${OS_VERSION}/x86_64/
enabled=1
gpgcheck=0
EOF
  tPackageExists subscription-manager || tPackageInstall subscription-manager
  yum install -y subscription-manager
}

@test "register subscription manager" {
  if [ -e "/etc/rhsm/ca/candlepin-local.pem" ]; then
    rpm -e `rpm -qf /etc/rhsm/ca/candlepin-local.pem`
  fi

  rpm -Uvh http://localhost/pub/katello-ca-consumer-latest.noarch.rpm || 0
  subscription-manager register --force --org=Default_Organization --environment=Library --username=admin --password=changeme
}

@test "check content host is registered" {
  hammer -u admin -p changeme content-host info --name $(hostname -f) --organization="Default Organization"
}

@test "collect important logs" {
  tail -n100 /var/log/{apache2,httpd}/*_log /var/log/foreman{-proxy,}/*log /var/log/messages > /root/last_logs || true
  foreman-debug -q -d /root/foreman-debug || true
  if tIsRedHatCompatible; then
    tPackageExists sos || tPackageInstall sos
    sosreport --batch --tmp-dir=/root || true
  fi
}
