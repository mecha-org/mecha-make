#!/usr/bin/env nu

use logger.nu

export def distro_info [rootfs_dir: string, package_conf_path: string] {

log_info "Updating os-release file"



let distro_info = open $package_conf_path | get os-release

# Convert os_info to the desired format
let os_release_content = $"
ID=($distro_info.ID)
ID_LIKE="($distro_info.ID_LIKE | str join ' ')"
NAME="($distro_info.NAME)"
VERSION="($distro_info.VERSION)"
VERSION_ID="($distro_info.VERSION_ID)"
VERSION_CODENAME="($distro_info.VERSION_CODENAME)"
PRETTY_NAME="($distro_info.PRETTY_NAME)"
HOME_URL="($distro_info.HOME_URL)"
SUPPORT_URL="($distro_info.SUPPORT_URL)"
BUG_REPORT_URL="($distro_info.BUG_REPORT_URL)"
"

  # Define the path to the os-release file
  let os_release_info_path = $rootfs_dir + "/usr/lib/os-release"

  # Write the formatted content to a temporary file
  let temp_file = "/tmp/os-release"
  echo $os_release_content | save --force $temp_file

  # Use sudo to move the temporary file to the desired location, overwriting the existing file
  sudo mv $temp_file $os_release_info_path

}

# change distro info