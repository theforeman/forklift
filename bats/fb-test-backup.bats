#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper

BACKUP_BASE_DIR="/var/tmp/foreman-backup"
BACKUP_OFFLINE_DIR="${BACKUP_BASE_DIR}/offline"
BACKUP_ONLINE_DIR="${BACKUP_BASE_DIR}/online"

@test "prepare system" {
  tForemanMaintainAvailable

  # this is implemented as a "test", as the bats in EPEL doesn't support
  # "setup_file" yet, and "setup" is executed before *each* test
  tForemanMaintainInstall

  # make sure we start clean
  rm -rf "${BACKUP_BASE_DIR}"
  mkdir -p "${BACKUP_OFFLINE_DIR}"
  mkdir -p "${BACKUP_ONLINE_DIR}"

  # this is a workaround for a https://projects.theforeman.org/issues/33947
  chmod 777 "${BACKUP_BASE_DIR}"
  chmod 777 "${BACKUP_OFFLINE_DIR}"
  chmod 777 "${BACKUP_ONLINE_DIR}"
}

@test "perform offline backup" {
  tForemanMaintainAvailable

  foreman-maintain backup offline --assumeyes --preserve-directory "${BACKUP_OFFLINE_DIR}"
}

@test "check offline backup contests for Foreman" {
  tForemanMaintainAvailable

  tFileExists "${BACKUP_OFFLINE_DIR}/config_files.tar.gz"
  tFileExists "${BACKUP_OFFLINE_DIR}/metadata.yml"
  tFileExists "${BACKUP_OFFLINE_DIR}/pgsql_data.tar.gz"
}

@test "check offline backup contents for Katello" {
  tForemanMaintainAvailable

  if ! tPackageExists foreman-installer-katello; then
    skip "Katello specific test"
  fi

  tFileExists "${BACKUP_OFFLINE_DIR}/pulp_data.tar"
}

@test "perform online backup" {
  tForemanMaintainAvailable

  foreman-maintain backup online --assumeyes --preserve-directory "${BACKUP_ONLINE_DIR}"
}

@test "check online backup contests for Foreman" {
  tForemanMaintainAvailable

  tFileExists "${BACKUP_ONLINE_DIR}/config_files.tar.gz"
  tFileExists "${BACKUP_ONLINE_DIR}/metadata.yml"
  tFileExists "${BACKUP_ONLINE_DIR}/foreman.dump"
}

@test "check online backup contents for Katello" {
  tForemanMaintainAvailable

  if ! tPackageExists foreman-installer-katello; then
    skip "Katello specific test"
  fi

  tFileExists "${BACKUP_ONLINE_DIR}/pulp_data.tar"
  tFileExists "${BACKUP_ONLINE_DIR}/candlepin.dump"
  tFileExists "${BACKUP_ONLINE_DIR}/pulpcore.dump"
}
