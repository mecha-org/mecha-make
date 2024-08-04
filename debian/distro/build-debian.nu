#!/usr/bin/env nu

# imports
use modules/logger.nu *
use modules/pkg.nu *
use modules/network-config.nu *
use modules/audio-config.nu *
use modules/distro-config.nu *
use modules/boot-config.nu *
use modules/system-config.nu *
use modules/user-config.nu *
use modules/kernel-config.nu *
use modules/pack-rootfs.nu *
use modules/os-config.nu *
use modules/clean-up.nu *
use modules/debootstrap.nu *


const BUILD_CONF_PATH = "./conf/build.yml" 

# Global aliases
alias SUDO = sudo
alias CHROOT = sudo chroot

# read build configuration file
let TARGET_HOSTNAME = open $BUILD_CONF_PATH | get hostname
let TARGET_LOCALE = open $BUILD_CONF_PATH | get locale
let TARGET_TIMEZONE = open $BUILD_CONF_PATH | get locale | get timezone

# Entrypoint
def main [machine: string, build_dir: string] {
  log_info "Building Mechanix (Debian)\n"

  log_debug $"Machine: ($machine)"

  let build_dir = $build_dir | path expand

  let work_dir = $build_dir + "/work"
  let deploy_dir = $build_dir + "/deploy"
  let tmp_dir = $work_dir + "/tmp"
  let rootfs_dir = $deploy_dir + "/rootfs"

  log_info "Build Configuration:"
  log_info $"Rootfs Directory: ($rootfs_dir)"
  log_info $"BUILD_DIR: ($build_dir)"
  log_info $"WORK_DIR: ($work_dir)"
  log_info $"DEPLOY_DIR: ($deploy_dir)\n"

  # Make build directories
  mkdir $build_dir
  mkdir $work_dir
  mkdir $deploy_dir
  mkdir $tmp_dir

  ## Set environment variables
  load-env {
    MACHINE: $machine,
    BUILD_DIR: $build_dir,
    WORK_DIR: $work_dir,
    DEPLOY_DIR: $deploy_dir,
    TMP_DIR: $tmp_dir,
    ROOTFS_DIR: $rootfs_dir,
    BUILD_CONF_PATH: $BUILD_CONF_PATH,
    # LC_ALL: "C",
    # LANGUAGE: "C",
    # LANG: "C"
  }

  # TODO: handle return code handling, create a stages runner


  try {

#-------------------------- Stage1: Setup rootfs -----------------------------#

#  install_host_packages

debootstrap_deb

copy_qemu_arm_static

mount_sys_proc_volumes

make_root_home_dir

configure_networking 

add_debian_mechanix_source

boot_script 

install_target_packages
  
disable_diaply_service

configure_audio 

update_os_release 

configure_udev

oem_images 

configure_bluetooth

configure_ssh 

configure_default_user

configure_greeter

configure_sys_files

  # Stage4: Cleanup
  unmount_sys_proc_volumes

  # Pack rootfs
  pack_root_fs 


  } catch {
    |err| 
    log_error $"Failed to build Mechanix: ($err)"
    clean_build_dir
  }

}


def copy_qemu_arm_static [] {
  log_info "Copying qemu-arm-static:"

   let rootfs_dir = $env.ROOTFS_DIR

  # # Check if `debootstrap` is installed
  # let is_qemu_arm_static_installed = dpkg -l | grep qemu-arm-static | wc -l | into int

  # # TODO: instead of checking with dpkg we can check with binary
  # if $is_qemu_arm_static_installed == 0 {
  #   log_error "`qemu-arm-static` is not installed, cannot continue further"
  #   return
  # }

  SUDO cp /usr/bin/qemu-arm-static $"($rootfs_dir)/usr/bin/"
}

def make_root_home_dir [] {
  log_info "Setting up root homedir:"
  let rootfs_dir = $env.ROOTFS_DIR

  CHROOT $rootfs_dir mkdir -p $"/home/root"
}

def mount_sys_proc_volumes [] {
  log_info "Mouting sys, proc volumes:"
  
  let rootfs_dir = $env.ROOTFS_DIR

    # Check if volumes are mounted before attempting to unmount
    if (SUDO mount | grep $"($rootfs_dir)/sys" | length) > 0 {
      SUDO mount sysfs $"($rootfs_dir)/sys" -t sysfs
    }
    if (SUDO mount | grep $"($rootfs_dir)/proc" | length) > 0 {
     SUDO mount proc $"($rootfs_dir)/proc" -t proc
    }


}

# def set_hostname [] {
#   log_info "Setting hostname:"
#   let rootfs_dir = $env.ROOTFS_DIR

#   CHROOT $rootfs_dir hostnamectl set-hostname $TARGET_HOSTNAME
# }



def setup_default_locale_timezone [] {
  log_info "Setting up default locale, timezone:"
  let rootfs_dir = $env.ROOTFS_DIR
  

#  CHROOT $rootfs_dir localectl set-locale $"LANG=($TARGET_LOCALE)"
  CHROOT $rootfs_dir timedatectl set-timezone $TARGET_TIMEZONE

  # TODO: Why is this disabled
  #$CHROOTCMD systemctl enable systemd-timesyncd
}

def update_apt [] {
  log_info "Updating apt and setting locale:"
    
  let rootfs_dir = $env.ROOTFS_DIR
  alias CHROOT = sudo chroot $rootfs_dir

  # clean up and update
#  CHROOT apt-get clean
#  CHROOT apt-get update
  CHROOT apt-get install locales
  CHROOT localectl set-locale LANG=en_US.UTF-8
}