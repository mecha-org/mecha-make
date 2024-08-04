#!/usr/bin/env nu

use logger.nu

export def update_os_release [] {

    log_info "Updating os-release file"

    let rootfs_dir = $env.ROOTFS_DIR
    let build_conf_path = $env.BUILD_CONF_PATH

    let os_info = open $build_conf_path | get os-release

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

export def oem_images [] {
    log_info "Setting boot logo:"
    let rootfs_dir = $env.ROOTFS_DIR
    let build_conf_path = $env.BUILD_CONF_PATH
    
    let media_files_location =  (open $build_conf_path | get media-files)
    let media_files_location = $media_files_location | path expand
  
    logger log_debug $"Script Directory Path: ($media_files_location)"
  
    let splash_image_dest = $rootfs_dir + "/boot/splash/"
    sudo mkdir -p $splash_image_dest
  
  
    let pattern = ($media_files_location | path join "*.bmp")
    glob $pattern | each { |file| sudo cp $file $splash_image_dest }
  
    log_debug "Setting logo Successfully."
}

export def disable_diaply_service [] {
    log_info "disabling display service:"
    let rootfs_dir = $env.ROOTFS_DIR

    let display_service = $rootfs_dir + /usr/lib/systemd/system/systemd-backlight@.service
    let disable_display_service = $rootfs_dir + /usr/lib/systemd/system/disabled-systemd-backlight@.service

    if ($display_service | path exists) {
        log_info $"Found display service at ($display_service). Disabling..."
        
        let result = (do {
            sudo mv $display_service $disable_display_service
        } | complete)

        if $result.exit_code == 0 {
            log_debug "Display service disabled successfully."
            return 0
        } else {
            log_error $"Failed to disable display service: ($result.stderr)"
            return 1
        }
    } else {
        log_info "Display service not found. No action needed."
        return 0
    }

}

export def keyboard_config [] {
    log_info "Configuring keyboard layout:"
    let rootfs_dir = $env.ROOTFS_DIR
    let build_conf_path = $env.BUILD_CONF_PATH

    let keyboard_layout = open $build_conf_path | get keyboard-config

    # Preset keyboard configuration options
    let keyboard_preset = $"
    keyboard-configuration keyboard-configuration/layoutcode string ($keyboard_layout.layout)
    keyboard-configuration keyboard-configuration/modelcode string ($keyboard_layout.model)
    keyboard-configuration keyboard-configuration/variantcode string ($keyboard_layout.variant)
    keyboard-configuration keyboard-configuration/optionscode string ($keyboard_layout.options)
    keyboard-configuration keyboard-configuration/toggle select ($keyboard_layout.toggle)
    "

    # Use chroot to set debconf selections
    echo $keyboard_preset | sudo chroot $rootfs_dir debconf-set-selections

    # Set DEBIAN_FRONTEND to noninteractive
    sudo chroot $rootfs_dir bash -c "export DEBIAN_FRONTEND=noninteractive && apt-get install -y keyboard-configuration"

    # Reconfigure keyboard-configuration to apply changes
    sudo chroot $rootfs_dir bash -c "dpkg-reconfigure -f noninteractive keyboard-configuration"
    log_info "Keyboard layout configured successfully."

}