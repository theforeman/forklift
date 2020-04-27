#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper

if [[ -e /etc/profile.d/puppet-agent.sh ]] ; then
  . /etc/profile.d/puppet-agent.sh
fi

@test "check smart proxy is registered" {
  hammer proxy info --name=$(hostname -f)
}

@test "assert puppet version" {
  if tIsRedHatCompatible ; then
    run grep -q puppetlabs /etc/yum.repos.d/*.repo
    IS_NATIVE=$status
  elif tIsDebianCompatible ; then
    run grep -q puppet\.com -R /etc/apt/sources.list*
    IS_NATIVE=$status
  else
    IS_NATIVE=1
  fi

  if tPackageExists puppet-agent ; then
    PACKAGE=puppet-agent
  else
    PACKAGE=puppet
  fi

  tPackageExists $PACKAGE
  if [[ $IS_NATIVE == 1 ]] ; then
    tPackageVendor $PACKAGE | grep -v "Puppet Labs"
  else
    tPackageVendor $PACKAGE | grep "Puppet Labs"
  fi
}

@test "wake up puppet agent" {
  puppet agent -t -v
}

@test "check host is registered" {
  hammer host info --name $(hostname -f) | egrep "Last report:.*[[:alnum:]]+"
}

# ENC / Puppet class apply tests
@test "install puppet module" {
  modpath=/etc/puppetlabs/code/environments/production/modules
  if [ ! -d $modpath -a -e /etc/puppet/environments/production/modules ]; then
    modpath=/etc/puppet/environments/production/modules
  fi

  if [ ! -d $modpath/motd ]; then
    puppet module install -i $modpath -v 0.1.0 theforeman/motd
  fi
  [ -e $modpath/motd/manifests/init.pp ]
}

@test "import motd puppet class" {
  hammer proxy import-classes --name $(hostname -f)
  count=$(hammer --csv puppet-class list --search 'name = motd' | wc -l)
  [ $count -gt 1 ]
}

@test "Assign environment to default taxonomies" {
  hammer environment update --name=production --locations "Default Location" --organizations "Default Organization"
}

@test "Assign proxy to default taxonomies" {
  # Foreman 1.20 and earlier didn't test with taxonomies on
  # Foreman 1.23 is expected to have a fix for this via https://projects.theforeman.org/issues/26092
  FOREMAN_VERSION=$(tForemanVersion)
  [[ $FOREMAN_VERSION != '1.21' ]] && [[ $FOREMAN_VERSION != '1.22' ]] && skip "Assignment not needed"
  hammer proxy update --name=$(hostname -f) --locations "Default Location" --organizations "Default Organization"
}

@test "assign puppet class to host" {
  id=$(hammer --csv puppet-class list --search 'name = motd' | tail -n1 | cut -d, -f1)
  hammer host update --puppet-class-ids $id --name $(hostname -f)
}

@test "apply class with puppet agent" {
  puppet agent -v -o --no-daemonize
  grep -i "property of the Foreman project" /etc/motd
}
