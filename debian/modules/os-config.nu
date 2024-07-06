#!/usr/bin/env nu

use logger.nu

export def update_os_release [rootfs_dir: string, package_conf_path: string] {

    log_info "Updating os-release file"

    let os_info = open $package_conf_path | get os-release

    # Convert os_info to the desired format
    let os_release_content = $"
    ID=($os_info.ID)
    ID_LIKE="($os_info.ID_LIKE | str join ' ')"
    NAME="($os_info.NAME)"
    VERSION="($os_info.VERSION)"
    VERSION_ID="($os_info.VERSION_ID)"
    VERSION_CODENAME="($os_info.VERSION_CODENAME)"
    PRETTY_NAME="($os_info.PRETTY_NAME)"
    HOME_URL="($os_info.HOME_URL)"
    SUPPORT_URL="($os_info.SUPPORT_URL)"
    BUG_REPORT_URL="($os_info.BUG_REPORT_URL)"
    "

    # Define the path to the os-release file
    let os_release_info_path = $rootfs_dir + "/usr/lib/os-release"

    # Write the formatted content to a temporary file
    let temp_file = "/tmp/os-release"
    echo $os_release_content | save --force $temp_file

    # Use sudo to move the temporary file to the desired location, overwriting the existing file
    sudo mv $temp_file $os_release_info_path

}

export def oem_images [rootfs_dir: string, package_conf_path: string] {
    log_info "Setting boot logo:"
  
    let media_files_location =  (open $package_conf_path | get media-files)
    let media_files_location = $media_files_location | path expand
  
    logger log_debug $"Script Directory Path: ($media_files_location)"
  
    let splash_image_dest = $rootfs_dir + "/boot/splash/"
    sudo mkdir -p $splash_image_dest
  
  
    let pattern = ($media_files_location | path join "*.bmp")
    glob $pattern | each { |file| sudo cp $file $splash_image_dest }
  
    log_debug "Setting logo Successfully."
}