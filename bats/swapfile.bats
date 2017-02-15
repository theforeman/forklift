#!/usr/bin/env bats
# vim: ft=sh:sw=2:ts=2:noet

set -o pipefail

@test "create swap file" {
  swapsize=5120 # in MB
  dd if=/dev/zero of=/swapfile bs=1048576 count=$swapsize
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap defaults 0 0' >> /etc/fstab
  sysctl vm.swappiness=60
}
