#!/usr/bin/env bats
# vim: ft=sh:sw=2:ts=2:noet

set -o pipefail

@test "install virt-whom" {
  git clone https://github.com/candlepin/virt-whom.git /usr/share/virt-whom
}

@test "report hypervisor guests to candlepin" {
  uuid=$(dmidecode | grep UUID | cut -d: -f2 | tr -d ' ' | tr '[:upper:]' '[:lower:]')
  sudo /usr/share/virt-whom/virt-whom -H hypervisor01.example.com:$uuid -e Library | grep -q 'Created host'
}

@test "hyerpvisor is created" {
  cat <<-EOF | foreman-rake console > /tmp/bats-hypervisor
  User.current = User.anonymous_admin
  system = Katello::System.find_by_name('hypervisor01.example.com')
  system.hypervisor?
	EOF
  tail -n2 /tmp/bats-hypervisor | grep -q true
}

@test "guest has the hypervisor set" {
  cat <<-EOF | foreman-rake console > /tmp/bats-guest
  User.current = User.anonymous_admin
  Katello::System.find_by_name('$(hostname -f)').virtual_host.name == 'hypervisor01.example.com'
	EOF
  tail -n2 /tmp/bats-guest | grep -q true
}
