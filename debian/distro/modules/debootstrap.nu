#!/usr/bin/env nu

use logger.nu

alias SUDO = sudo
alias CHROOT = sudo chroot

export def debootstrap_deb [] {
  log_info "Debootstrapping debian:"
  let work_dir = $env.WORK_DIR;
  let tmp_dir = $env.TMP_DIR;
  let deploy_dir = $env.DEPLOY_DIR;
  let rootfs_dir = $env.ROOTFS_DIR;
  let BUILD_CONF_PATH = $env.BUILD_CONF_PATH;

  # Check if `debootstrap` is installed
  let $is_deboostrap_installed = dpkg -l | grep debootstrap | length

  # Install `debootstrap` package, if not installed
  if $is_deboostrap_installed == 0 {
    log_error "`debootstrap` is not installed, cannot continue further."
    return
  }

  let debian_name = open $BUILD_CONF_PATH | get debian | get name
 
  # TODO: uncomment
  SUDO debootstrap --arch arm64 --foreign --no-check-gpg --include=eatmydata,gnupg $debian_name $rootfs_dir http://deb.debian.org/debian
  CHROOT $rootfs_dir /debootstrap/debootstrap --second-stage
}