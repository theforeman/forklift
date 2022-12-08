#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper

BACKUP_DIR=/var/tmp/foreman-backup

@test "prepare system" {
  tForemanMaintainAvailable

  # this is implemented as a "test", as the bats in EPEL doesn't support
  # "setup_file" yet, and "setup" is executed before *each* test
  tForemanMaintainInstall

  # make sure we start clean
  rm -rf $BACKUP_DIR
  mkdir -p $BACKUP_DIR

  # this is a workaround for a https://projects.theforeman.org/issues/33947
  chmod 777 $BACKUP_DIR
}

@test "perform backup" {
  tForemanMaintainAvailable

  foreman-maintain backup offline --assumeyes --preserve-directory ${BACKUP_DIR}
}

@test "check backup contests for Foreman" {
  tForemanMaintainAvailable

  tFileExists ${BACKUP_DIR}/config_files.tar.gz
  tFileExists ${BACKUP_DIR}/metadata.yml
  tFileExists ${BACKUP_DIR}/pgsql_data.tar.gz
}

@test "check backup contents for Katello" {
  tForemanMaintainAvailable

  if ! tPackageExists foreman-installer-katello; then
    skip "Katello specific test"
  fi

  tFileExists ${BACKUP_DIR}/pulp_data.tar
}
