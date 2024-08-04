#!/usr/bin/env nu

use logger.nu

export def copy_linux_kernel_dtb_modules [rootfs_dir: string, package_conf_path: string] {

log_info "Copying Linux kernel, dtb, modules, and firmware to appropriate directories:"


let package_dir_path = (open $package_conf_path | get packages-path)

let temp_dir = $rootfs_dir + "/tmp"
 

 # Copy files from package_dir_path/kernel/ to rootfs_dir/temp
let kernel_dir = $package_dir_path + "/kernel"
let kernel_pattern = ($kernel_dir | path join "*")
glob $kernel_pattern | each { |file| sudo cp $file $temp_dir }

# Copy files from package_dir_path/kernel-modules-20march/ to rootfs_dir/temp
let kernel_modules_dir = $package_dir_path + "/kernel-modules-20march"
let kernel_modules_pattern = ($kernel_modules_dir | path join "*")
glob $kernel_modules_pattern | each { |file| sudo cp $file $temp_dir }

# Copy files from package_dir_path/firmware/ to rootfs_dir/temp
let firmware_dir = $package_dir_path + "/firmware"
let firmware_pattern = ($firmware_dir | path join "*")
glob $firmware_pattern | each { |file| sudo cp $file $temp_dir }

# Copy files from package_dir_path/libubootenv/ to rootfs_dir/temp
let libubootenv_dir = $package_dir_path + "/libubootenv"
let libubootenv_pattern = ($libubootenv_dir | path join "*")
glob $libubootenv_pattern | each { |file| sudo cp $file $temp_dir }

}