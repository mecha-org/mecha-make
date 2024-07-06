#!/usr/bin/env nu

use logger.nu


export def enable_easysplash [rootfs_dir: string] {

  log_info "Enabling easysplash service:"



  alias CHROOT = sudo chroot $rootfs_dir
  alias SUDO = sudo
  CHROOT systemctl enable easysplash-start.service
  CHROOT systemctl enable easysplash-quit.service

  log_debug "Enabling easysplash service Successfully."
  # $CHROOTCMD systemctl enable easysplash-start.service
  # $CHROOTCMD systemctl enable easysplash-quit.service
}

export def enable_boot_fw [rootfs_dir: string] {
  log_info "Enabling boot-fw service:"


  alias CHROOT = sudo chroot $rootfs_dir

  CHROOT systemctl enable boot-fw.service
  CHROOT systemctl enable boot-fw-quit.service


  log_debug "Enabling boot-fw service Successfully."

  # sudo cp $ROOTDIR/../../scripts/fw_env.config $ROOTDIR/etc
  # sudo cp $ROOTDIR/../../scripts/u-boot-initial-env $ROOTDIR/etc
}

export def boot_script [rootfs_dir: string, package_conf_path: string] {
  log_info "Setting boot script:"

  alias CHROOT = sudo chroot $rootfs_dir
  alias SUDO = sudo
  let script_dir_path =  (open $package_conf_path | get scripts-path)
  logger log_debug $"Script Directory Path: ($script_dir_path)"


  # we can get the kernel version from the kernel config file
  let kernel_version = '6.1.22+mecha'

  let boot_script_source = $script_dir_path + "/boot.script"
  let boot_script_to_scr = $script_dir_path + "/boot.scr"



  # Read the file content
  let content = (open $boot_script_source)

  # Replace the old version with the new version
  let updated_content = ($content | str replace 'kernel_version' $kernel_version)
  log_debug $"Modified Script: ($updated_content)"


  # Save the updated content back to the file
  $updated_content | save -f $boot_script_source

  # make the boot script
  mkimage -c none -A arm -T script -d $boot_script_source $boot_script_to_scr

  # boot script destination on the rootfs
  let boot_script_dest = $rootfs_dir + "/boot/boot.scr"

  SUDO cp $boot_script_to_scr $boot_script_dest

}


def hello [] {
   print "Hello, World!"

   # Define the file path and the new version value as arguments
   let script_dir_path = "/home/jack/Desktop/mecha/mecha-make-v1/debian/include/scripts"
  let boot_script_source = $script_dir_path + "/boot.script"
  let new_version = "new_value"  # Replace with the actual new value you want to pass

  # Read the file content
  let content = (open $boot_script_source)

   # Replace the old version with the new version
  let updated_content = ($content | str replace 'kernel_version' $new_version)

  # Save the updated content back to the file
  print $updated_content
 }


