#!/usr/bin/env nu

use logger.nu

alias SUDO = sudo

export def unmount_sys_proc_volumes [] {
  log_info "Unmounting sys, proc volumes:"

  let rootfs_dir = $env.ROOTFS_DIR

  # Check if volumes are mounted before attempting to unmount
  if (SUDO mount | grep $"($rootfs_dir)/sys" | length) > 0 {
    log_debug "Unmounting sys volume"
    SUDO umount $"($rootfs_dir)/sys"
  }
  if (SUDO mount | grep $"($rootfs_dir)/proc" | length) > 0 {
    log_debug "Unmounting proc volume"
    SUDO umount $"($rootfs_dir)/proc"
  }
}


export def clean_build_dir [] {
  log_info "Ensuring all volumes are unmounted"
  try {
    unmount_sys_proc_volumes
  } catch {
    |err| 
    log_warn $"Failed to unmount volumes: ($err)"
  }
}