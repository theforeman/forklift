#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper

BACKUP_DIR=/var/tmp/foreman-backup

@test "prepare system" {
  tIsRHEL || skip 'foreman_maintain is not available on non-RHEL'

  # this is implemented as a "test", as the bats in EPEL doesn't support
  # "setup_file" yet, and "setup" is executed before *each* test

  tPackageExists rubygem-foreman_maintain || tPackageInstall rubygem-foreman_maintain

  # make sure we start clean
  rm -rf $BACKUP_DIR
  mkdir -p $BACKUP_DIR

  # this is a workaround for a https://projects.theforeman.org/issues/33947
  chmod 777 $BACKUP_DIR
}

@test "perform backup" {
  tIsRHEL || skip 'foreman_maintain is not available on non-RHEL'

  foreman-maintain backup offline --assumeyes --preserve-directory ${BACKUP_DIR}
}

@test "check backup contests for Foreman" {
  tIsRHEL || skip 'foreman_maintain is not available on non-RHEL'

  tFileExists ${BACKUP_DIR}/config_files.tar.gz
  tFileExists ${BACKUP_DIR}/metadata.yml
  tFileExists ${BACKUP_DIR}/pgsql_data.tar.gz
}

@test "check backup contents for Katello" {
  tIsRHEL || skip 'foreman_maintain is not available on non-RHEL'

  if ! tPackageExists foreman-installer-katello; then
    skip "Katello specific test"
  fi

  tFileExists ${BACKUP_DIR}/pulp_data.tar
}
