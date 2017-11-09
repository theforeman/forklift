#!/usr/bin/env bats
# vim: ft=sh:sw=2:ts=2:et

set -o pipefail

load os_helper
load foreman_helper

tSetNameserver() {
  run tGetRecord ch txt version.bind
  case $output in
    *PowerDNS*)
      NAMESERVER="powerdns"
      ;;
    *)
      NAMESERVER="bind"
      ;;
  esac
}

tSpRequest() {
  if [ -d /etc/puppetlabs/puppet/ssl ] ; then
    SP_KEY=/etc/puppetlabs/puppet/ssl/private_keys/${HOSTNAME}.pem
    SP_CERT=/etc/puppetlabs/puppet/ssl/certs/${HOSTNAME}.pem
    SP_CACERT=/etc/puppetlabs/puppet/ssl/ca/ca_crt.pem
  else
    SP_KEY=/var/lib/puppet/ssl/private_keys/${HOSTNAME}.pem
    SP_CERT=/var/lib/puppet/ssl/certs/${HOSTNAME}.pem
    SP_CACERT=/var/lib/puppet/ssl/ca/ca_crt.pem
  fi

  local url=https://${HOSTNAME}:8443/$1
  shift
  curl --silent --fail --key $SP_KEY --cert $SP_CERT --cacert $SP_CACERT $* $url
}

tGetRecord() {
  dig +short @localhost $*
}

tVerifyRecord() {
  local name=$1
  local type=$2
  local expected=$3

  tFlushCache $name
  run tGetRecord $type $name
  [[ $status == 0 ]]
  [[ $output == $expected ]]
}

tCreateRecord() {
  local fqdn=$1
  local value=$2
  local type=$3
  tSpRequest dns/ -X POST -d fqdn=$fqdn -d value=$value -d type=$type
}

tDeleteRecord() {
  local name=$1
  local type=$2
  tSpRequest dns/$name/$type -X DELETE
}

tFlushCache() {
  case $NAMESERVER in
    powerdns)
      pdns_control purge $1
      ;;
  esac
}

setup() {
  tSetOSVersion
  FOREMAN_VERSION=$(tForemanVersion)

	tCommandExists curl || tPackageInstall curl
	tCommandExists dig || tPackageInstall bind-utils || tPackageInstall dnsutils

  tSetNameserver

  export HOSTNAME=$(hostname -f)
}

@test "verify dns feature is enabled" {
  tSpRequest features | grep '"dns"'
}

@test "clean up any existing records" {
  for type in A AAAA CNAME ; do
    run tDeleteRecord bats-test.example.com $type
  done
  run tDeleteRecord 254.121.168.192.in-addr.arpa PTR
  run tDeleteRecord 1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa PTR
  run tDeleteRecord bats-alias.example.com CNAME
}

@test "verify record type A" {
  local fqdn=bats-test.example.com
  local ip=192.0.2.100
  local type=A

  tCreateRecord $fqdn $ip $type
  tVerifyRecord $fqdn $type $ip

  tDeleteRecord $fqdn $type
  tVerifyRecord $fqdn $type ""
}

@test "verify record type AAAA" {
  local fqdn=bats-test.example.com
  local ip=2001:db8::1
  local type=AAAA

  tCreateRecord $fqdn $ip $type
  tVerifyRecord $fqdn $type $ip

  tDeleteRecord $fqdn $type
  tVerifyRecord $fqdn $type ""
}

@test "verify record type PTR v4" {
  local fqdn=bats-test.example.com
  local reverse=254.121.168.192.in-addr.arpa
  local type=PTR

  tCreateRecord $fqdn $reverse $type
  tVerifyRecord $reverse $type ${fqdn}.

  tDeleteRecord $reverse $type
  tVerifyRecord $reverse $type ""
}

@test "verify record type PTR v6" {
  local fqdn=bats-test.example.com
  local reverse=1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa
  local type=PTR

  tCreateRecord $fqdn $reverse $type
  tVerifyRecord $reverse $type ${fqdn}.

  tDeleteRecord $reverse $type
  tVerifyRecord $reverse $type ""
}

@test "verify record type CNAME" {
  if [[ $NAMESERVER == "bind" ]] && [[ $(echo "$FOREMAN_VERSION < 1.15" | bc) == 1 ]] ; then
    skip "CNAME records are only supported on 1.15+"
  fi

  local target=bats-test.example.com
  local alias=bats-alias.example.com
  local type=CNAME

  tCreateRecord $alias $target $type
  tVerifyRecord $alias $type ${target}.

  tDeleteRecord $alias $type
  tVerifyRecord $alias $type ""
}
