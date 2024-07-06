#!/usr/bin/env nu

use logger.nu

alias SUDO = sudo

export def configure_audio [rootfs_dir: string, package_dir_path: string] {
  log_info "Configuring audio:"

  log_debug $"package_dir_path: ($package_dir_path)"

  let package_dir_path = open $package_dir_path | get packages-path

  
  let asound_state_src = $package_dir_path + "/asound.state"
  let asound_conf_src = $package_dir_path + "/asound.conf"

  let asound_state_dest = $rootfs_dir + "/var/lib/alsa/asound.state"
  let asound_conf_dest = $rootfs_dir + "/etc/asound.conf"

  log_info $"Copying ($asound_state_src) to ($asound_state_dest)"
  log_info $"Copying ($asound_conf_src) to ($asound_conf_dest)"

  # Copy the files
  SUDO cp $asound_state_src $asound_state_dest
  SUDO cp $asound_conf_src $asound_conf_dest
  # sudo cp $ROOTDIR/../../scripts/daemon.conf $rootfs_dir/etc/pulse/
}