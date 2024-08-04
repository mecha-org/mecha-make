


#!/usr/bin/env nu

use logger.nu

alias SUDO = sudo

export def configure_sys_files [] {

  log_info "Configuring system files:"
  let rootfs_dir = $env.ROOTFS_DIR
  let build_conf_path = $env.BUILD_CONF_PATH
  

  let script_dir_path =  (open $build_conf_path | get include-path)

  let domain_contet = '127.0.0.1       localhost.localdomain           comet-m'
  let temp_file = "/tmp/domain-content"

  echo $domain_contet | save --force $temp_file

  let hosts_dest = $rootfs_dir + "/etc/hosts"

  SUDO mv $temp_file $hosts_dest

  let hostname_content = "comet-m"
  let temp_file = "/tmp/hostname-content"

  echo $hostname_content | save --force $temp_file

  let hostname_dest = $rootfs_dir + "/etc/hostname"

  SUDO mv $temp_file $hostname_dest

  let issue_content = "Welcome Mechanix V1.1 \n"
  let temp_file = "/tmp/issue-content"

  echo $issue_content | save --force $temp_file

  let issue_dest = $rootfs_dir + "/etc/issue"

  SUDO mv $temp_file $issue_dest

  let motd_content = "---------Mecha-Comet-M-Gen1---------"
  let temp_file = "/tmp/motd-content"

  echo $motd_content | save --force $temp_file

  let motd_dest = $rootfs_dir + "/etc/motd"

  SUDO mv $temp_file $motd_dest

  let fstab_src = $script_dir_path + "/fstab"
  let fstab_dest = $rootfs_dir + "/etc/fstab"

  SUDO cp $fstab_src $fstab_dest

  let logind_conf_content = "HandlePowerKey=ignore"
  let temp_file = "/tmp/logind-conf-content"

  echo $logind_conf_content | save --force $temp_file

  let logind_conf_dest = $rootfs_dir + "/etc/systemd/logind.conf"

  SUDO mv $temp_file $logind_conf_dest

}

export def configure_greeter [] {
  log_info "Configuring greeter:"
  let rootfs_dir = $env.ROOTFS_DIR

  alias CHROOT = sudo chroot $rootfs_dir

  # Create greeter user for greetd, enable greetd-service and disable getty-service
  # log_debug "Creating greeter user for greetd, enabling greetd-service and disabling getty-service"
  # CHROOT useradd -M greeter
  # CHROOT usermod -aG video greeter
  # CHROOT usermod -aG render greeter
  # CHROOT usermod -d /usr/greeter greeter

  let config_append = "
  # Performs auto login for default user
  [initial_session]
  command = \"sway\"
  user = \"mecha\"
  "

  let greetd_config_path = $rootfs_dir + "/etc/greetd/config.toml"
  echo $config_append | sudo tee -a $greetd_config_path

  CHROOT systemctl disable getty@tty1.service
  CHROOT systemctl enable greetd.service

}



export def configure_ssh [] {
  log_info "Configuring ssh:"
  let rootfs_dir = $env.ROOTFS_DIR
  let build_conf_path = $env.BUILD_CONF_PATH

  let script_dir_path =  (open $build_conf_path | get include-path)
  alias CHROOT = sudo chroot $rootfs_dir

  #CHROOT rm /etc/ssh/ssh_host_*
  CHROOT mkdir -p /usr/libexec/openssh

  let sshd_check_keys_src = $script_dir_path + "/sshd-key-gen/sshd_check_keys"
  let sshd_check_keys_dest = $rootfs_dir + "/usr/libexec/openssh"

  log_debug $"Copying ($sshd_check_keys_src) to ($sshd_check_keys_dest)"
  SUDO cp $sshd_check_keys_src $sshd_check_keys_dest
  SUDO chmod 744 $"($rootfs_dir)/usr/libexec/openssh/sshd_check_keys"

  let sshdgenkeys_service_src = $script_dir_path + "/sshd-key-gen/sshdgenkeys.service"
  let sshdgenkeys_service_dest = $rootfs_dir + "/lib/systemd/system"

  log_debug $"Copying ($sshdgenkeys_service_src) to ($sshdgenkeys_service_dest)"
  SUDO cp $sshdgenkeys_service_src $sshdgenkeys_service_dest

  log_debug "Enabling sshdgenkeys service"
  CHROOT systemctl enable sshdgenkeys.service
  log_debug "Enabling sshdgenkeys service Successfully."

}


export def configure_udev [] {

  log_info "Configuring udev:"

  let rootfs_dir = $env.ROOTFS_DIR
  let build_conf_path = $env.BUILD_CONF_PATH

  let script_dir_path =  (open $build_conf_path | get include-path)


  let udev_rules_src = $script_dir_path + "/10-imx.rules"
  let udev_rules_dest = $rootfs_dir + "/etc/udev/rules.d/10-imx.rules"

  log_info $"Copying ($udev_rules_src) to ($udev_rules_dest)"
  SUDO cp $udev_rules_src $udev_rules_dest
}


export def enable_watchdog_timer [rootfs_dir: string] {
  ### Enable Watchdog Timer 
  log_info "Enabling Watchdog Timer:"


  let watchdog_conf_path = $rootfs_dir + "/etc/systemd/system.conf"

  let tmp_watchdog_conf = "/tmp/watchdog.conf"

  let watchdog_timer = "RuntimeWatchdogSec=30"

  echo $watchdog_timer | save --force $tmp_watchdog_conf

  SUDO mv $tmp_watchdog_conf $watchdog_conf_path

}