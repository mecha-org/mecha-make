#!/usr/bin/env nu

use logger.nu

alias SUDO = sudo

export def pack_root_fs [rootfs_dir: string, deploy_dir: string] {


  log_info "Packing rootfs:"

  log_debug $"Rootfs Directory: ($rootfs_dir)"

  let tar_file_dir = $deploy_dir + "/debian-image-rootfs.tar.gz"

   SUDO tar -czvf $tar_file_dir -C $rootfs_dir .

  log_info "Successfully packed rootfs"
  log_debug $"Rootfs packed at: ($tar_file_dir)"

}
