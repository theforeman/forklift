#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper

setup() {
  HOSTNAME="$(hostname -f)"
  export HOSTNAME
}

if [[ -e /etc/profile.d/puppet-agent.sh ]] ; then
  . /etc/profile.d/puppet-agent.sh
fi

@test "enable puppet feature" {
  KATELLO_VERSION=$(tKatelloVersion)
  if ! tIsVersionNewer "${KATELLO_VERSION}" 4.3; then
    skip "Enabling Puppet explicitly is only needed with Katello 4.3+"
  fi

  SCENARIO=$(tScenario)
  grep -q 'foreman::plugin::puppet: false' "/etc/foreman-installer/scenarios.d/${SCENARIO}-answers.yaml" || skip "Puppet plugin already enabled"

  # Foreman 3.1 made Puppet optional for Katello (https://projects.theforeman.org/issues/33337)
  # Foreman 3.6 made a bunch of parameters no longer needed (https://projects.theforeman.org/issues/35985)
  FOREMAN_VERSION=$(tForemanVersion)
  if ! tIsVersionNewer "${FOREMAN_VERSION}" 3.6; then
    cert_options=(--foreman-proxy-content-puppet true --puppet-server-foreman-ssl-ca /etc/pki/katello/puppet/puppet_client_ca.crt --puppet-server-foreman-ssl-cert /etc/pki/katello/puppet/puppet_client.crt --puppet-server-foreman-ssl-key /etc/pki/katello/puppet/puppet_client.key)
  fi

  foreman-installer --enable-foreman-plugin-puppet --enable-foreman-cli-puppet --foreman-proxy-puppet true --foreman-proxy-puppetca true --enable-puppet --puppet-server true "${cert_options[@]}"
  # Force hammer to reload the apidoc cache - https://projects.theforeman.org/issues/28283
  hammer --reload-cache ping
}

@test "check smart proxy is registered" {
  hammer proxy info --name="$(hostname -f)"
}

@test "assert puppet version" {
  if tIsRedHatCompatible ; then
    run grep -q -E 'puppet(labs)?\.com' /etc/yum.repos.d/*.repo
    IS_NATIVE=$status
  elif tIsDebianCompatible ; then
    run grep -q -E 'puppet(labs)?\.com' -R /etc/apt/sources.list*
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
  local next_wait_time=0
  until [ ! -f /opt/puppetlabs/puppet/cache/state/agent_catalog_run.lock -o $next_wait_time -eq 12 ]; do
    sleep $(( next_wait_time++ ))
  done

  puppet agent -t -v
}

@test "check host is registered" {
  hammer host info --name "$(hostname -f)" | grep -E "Last report:.*[[:alnum:]]+"
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
  hammer proxy import-classes --name "$(hostname -f)"
  count=$(hammer --csv puppet-class list --search 'name = motd' | wc -l)
  [ "${count}" -gt 1 ]
}

@test "assign puppet-environment to default taxonomies" {
  hammer puppet-environment update --name=production --locations "Default Location" --organizations "Default Organization"
}

@test "assign puppet class to host" {
  id=$(hammer --csv puppet-class list --search 'name = motd' | tail -n1 | cut -d, -f1)
  hammer host update --puppet-class-ids "${id}" --name "$(hostname -f)"
}

@test "apply class with puppet agent" {
  puppet agent -v -o --no-daemonize
  grep -i "property of the Foreman project" /etc/motd
}

@test "ensure there is a report for Puppet" {
  REPORT_ID=$(hammer --output csv --no-headers config-report list --fields "Id" --search "host=${HOSTNAME} origin=Puppet")
  hammer config-report info --id "${REPORT_ID%%[[:space:]]*}" | grep "Resource: Puppet"
}
