#!/usr/bin/env nu

use logger.nu

alias SUDO = sudo

export def pack_root_fs [] {


  log_info "Packing rootfs:"
  let rootfs_dir = $env.ROOTFS_DIR
  let deploy_dir = $env.DEPLOY_DIR

  log_debug $"Rootfs Directory: ($rootfs_dir)"
  log_debug $"Deploy Directory: ($deploy_dir)"

  let tar_file_dir = $deploy_dir + "/debian-image-rootfs.tar.gz"

   SUDO tar -czvf $tar_file_dir -C $rootfs_dir .

  log_info "Successfully packed rootfs"
  log_debug $"Rootfs packed at: ($tar_file_dir)"

}
