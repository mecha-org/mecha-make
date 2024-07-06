#!/usr/bin/env nu

use logger.nu

alias SUDO = sudo

export def configure_default_user [rootfs_dir: string, package_conf_path: string] {
   log_info "Configuring default user:"

  let rootfs_dir = $env.ROOTFS_DIR

  alias CHROOT = sudo chroot $rootfs_dir

  let user_data = open $package_conf_path | get user 
  let user_name = $user_data.name
  let user_password = $user_data.password

  log_debug $"Creating user: ($user_name)"
  
  let salt = random chars --length 10
  let passwd_hash = mkpasswd -m sha-512 $user_password -s $salt

  CHROOT useradd -m -u 1001 -p $passwd_hash $user_name

  let user_home_dir = "/home/" + $user_name

  CHROOT mkdir -p $user_home_dir
  
  let user_profile_path = $user_home_dir + "/.profile"
  let destination_profile_path = $rootfs_dir + $user_profile_path

  let profile_content = "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

  # crate temp file with profile content
  let temp_file = "/tmp/.profile"

  echo $profile_content | save --force $temp_file

  # Copy the profile content to the destination
  SUDO cp $temp_file $destination_profile_path

  # remove the temp file
  rm $temp_file

  # sudo bash -c ("echo 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' > $rootfs_dir/home/mecha/.profile")

  log_debug $"Adding user to groups: ($user_name)"
  CHROOT usermod -aG sudo $user_name
  CHROOT usermod -aG video $user_name
  CHROOT usermod -aG audio $user_name
  CHROOT usermod -aG input $user_name
  CHROOT usermod -aG render $user_name
  CHROOT usermod -aG netdev $user_name
  CHROOT chsh -s /bin/bash $user_name
}