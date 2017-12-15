#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper

@test "check smart proxy is registered" {
  hammer proxy info --name=$(hostname -f)
}

@test "assert puppet version" {
  if tIsRedHatCompatible ; then
    run grep -q puppetlabs /etc/yum.repos.d/*.repo
    IS_NATIVE=$status
  elif tIsDebianCompatible ; then
    run grep -q puppetlabs -R /etc/apt/sources.list*
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

  if [ ! -d $modpath/ntp ]; then
    puppet module install -i $modpath -v 4.2.0 puppetlabs/ntp
  fi
  [ -e $modpath/ntp/manifests/init.pp ]
}

@test "import ntp puppet class" {
  id=$(hammer --csv proxy list | tail -n1 | cut -d, -f1)
  hammer proxy import-classes --id $id
  count=$(hammer --csv puppet-class list --search 'name = ntp' | wc -l)
  [ $count -gt 1 ]
}

@test "assign puppet class to host" {
  id=$(hammer --csv puppet-class list --search 'name = ntp' | tail -n1 | cut -d, -f1)
  pc_ids=$(hammer host update --help | awk '/class-ids/ {print $1}')
  hammer host update $pc_ids $id --name $(hostname -f)
}

@test "apply class with puppet agent" {
  puppet agent -v -o --no-daemonize
  grep -i puppet /etc/ntp.conf
}
