#!/usr/bin/env nu
use logger.nu

const HOST_INSTALLATION_CONF = "conf-packages/host.yml"
const TARGET_INSTALLATION_CONF = "conf-packages/target.yml"


alias CHROOT = sudo chroot

def install_package [name: string, url: string, sha] {
    let tmp_dir = $env.TMP_DIR
    let pkg_path = $"($tmp_dir)/($name)-($sha).deb"

    log_debug $"Downloading ($name) ..."
    wget -q $url -P $tmp_dir -O $pkg_path

    log_debug $"Installing ($name) ..."
    SUDO dpkg -i $pkg_path

    log_debug $"Package ($name) is installed"

    # TODO: Verify SHA
    # TODO: avoid redownload, if file exists + SHA matched
}

export def install_host_packages [] {
    log_info "Installing host packages:"

    # add the package source
    

    # let packages = open $HOST_INSTALLATION_CONF;
    log_debug $"Number of packages found: (open $HOST_INSTALLATION_CONF | get packages | length)"

    let _  = open $HOST_INSTALLATION_CONF | get packages | each {|pkg| 
        install_package $pkg.name $pkg.url $pkg.sha
    }
}

export def install_linux_kernel_packages [] {
    log_info "Installing linux kernel packages:"

    let rootfs_dir = $env.ROOTFS_DIR
    let deploy_dir = $env.DEPLOY_DIR
    alias CHROOT = sudo chroot $rootfs_dir

    # copy the debs
    let kernel_version = "6.1.22+mecha"
    let kernel_build = "1"
    let target_arch = "arm64"

    let linux_image_deb = $"linux-image-($kernel_version)_($kernel_version)-($kernel_build)_($target_arch).deb"
    let linux_headers_deb = $"linux-headers-($kernel_version)_($kernel_version)-($kernel_build)_($target_arch).deb"
    let linux_libc_dev_deb = $"linux-libc-dev_($kernel_version)-($kernel_build)_($target_arch).deb"

    sudo cp $"($deploy_dir)/kernel/debs/($linux_image_deb)" $"($rootfs_dir)/tmp"
    sudo cp $"($deploy_dir)/kernel/debs/($linux_headers_deb)" $"($rootfs_dir)/tmp"
    sudo cp $"($deploy_dir)/kernel/debs/($linux_libc_dev_deb)" $"($rootfs_dir)/tmp"


    CHROOT apt-get update
    CHROOT apt-get -y install initramfs-tools
    CHROOT dpkg -i $"/tmp/($linux_image_deb)"
    CHROOT dpkg -i $"/tmp/($linux_headers_deb)"
    CHROOT dpkg -i $"/tmp/($linux_libc_dev_deb)"

    # TODO: remove from rootfs/tmp
}

export def install_linux_firmware_packages [] {
    log_info "Installing linux firmware packages:"

    let rootfs_dir = $env.ROOTFS_DIR
    let deploy_dir = $env.DEPLOY_DIR
    let build_conf_path = $env.BUILD_CONF_PATH
    alias CHROOT = sudo chroot $rootfs_dir

    # copy the debs
    let firmware_imx_sdma = "firmware-imx-sdma-imx7d_8.20-r0_all.deb"
    let firmware_broadcom_license = "linux-firmware-broadcom-license_20230210-r0_all.deb"
    let firmware_bcm4355 = "linux-firmware-bcm43455_20230210-r0_all.deb"

    let firmware_path =   (open $build_conf_path | get firmware-files) 
    let firmware_path = $firmware_path | path expand

    let include_path =   (open $build_conf_path | get include-path)
    let include_path = $include_path | path expand

    log_debug $"Firmware path: ($firmware_path)"

    sudo cp $"($firmware_path)/($firmware_imx_sdma)" $"($rootfs_dir)/tmp"
    sudo cp $"($firmware_path)/($firmware_broadcom_license)" $"($rootfs_dir)/tmp"
    sudo cp $"($firmware_path)/($firmware_bcm4355)" $"($rootfs_dir)/tmp"

    # need to check what is this for
    # sudo cp $"($include_path)/usr/share/initramfs-tools/hooks/broadcom-bcm43455" $"($rootfs_dir)/usr/share/initramfs-tools/hooks"
    # sudo cp $"($include_path)/usr/share/initramfs-tools/hooks/imx-sdma" $"($rootfs_dir)/usr/share/initramfs-tools/hooks"
    sudo cp $"($include_path)/usr/share/initramfs-tools/hooks/broadcom-bcm43455" $"($rootfs_dir)/usr/share/initramfs-tools/hooks"
    sudo cp $"($include_path)/usr/share/initramfs-tools/hooks/imx-sdma" $"($rootfs_dir)/usr/share/initramfs-tools/hooks"

    CHROOT dpkg -i $"/tmp/($firmware_imx_sdma)"
    CHROOT dpkg -i $"/tmp/($firmware_broadcom_license)"
    CHROOT dpkg -i $"/tmp/($firmware_bcm4355)"

    # TODO: remove from rootfs/tmp
}

export def install_target_packages [] {

    log_info "Installing target packages:"
    
    let rootfs_dir = $env.ROOTFS_DIR
    alias CHROOT = sudo chroot $rootfs_dir

    # clean up and update
    CHROOT apt-get clean
    CHROOT apt-get update


    let package_groups = open $TARGET_INSTALLATION_CONF | get package_groups

    for pkg_group in $package_groups {
        log_debug $"Installing package group: ($pkg_group.packages)"

        # Check if the length of the list of packages is 0
        if ($pkg_group.packages | length) == 0 {
            log_debug "No packages found in this group."
        } else {
            # Iterate over each package within the group
            for pkg in $pkg_group.packages {
                log_debug $"Installing package: ($pkg)"
                # Install the package
                CHROOT apt-get -y --allow-change-held-packages install $pkg
            }
        }
    }

  
}

def add_debian_mechanix_source [] {
    let rootfs_dir = $env.ROOTFS_DIR
    alias CHROOT = sudo chroot $rootfs_dir

    let sources_list_path = "/etc/apt/sources.list"

    # Get the package source from the YAML configuration
    let build_conf_path = $env.BUILD_CONF_PATH
    let deb_package_sources = open $build_conf_path | get apt | get sources

    log_info "Adding Mechanix package sources to sources.list"

    # Iterate through each source and add it to sources.list
    $deb_package_sources | each { |source|
        let source_line = $"deb [trusted=yes] ($source)"
        log_debug $"Adding source: ($source_line)"
        
        sudo chroot $rootfs_dir bash -c $"echo '($source_line)' >> ($sources_list_path)"

        if $env.LAST_EXIT_CODE != 0 {
            log_error $"Failed to add source: ($source_line)"
            return
        }
    }

    log_info "Successfully added all Mechanix package sources"

    # Update package lists
    log_info "Updating package lists"
    CHROOT apt-get update

    if $env.LAST_EXIT_CODE == 0 {
        log_info "Successfully updated package lists"
    } else {
        log_error "Failed to update package lists"
    }
}

export def install_mechanix_packages [] {
    log_info "Installing Mechanix packages:"

    let rootfs_dir = $env.ROOTFS_DIR
    alias CHROOT = sudo chroot $rootfs_dir

    add_debian_mechanix_source

     # Get package groups from the YAML file
    let package_groups = open $TARGET_INSTALLATION_CONF | get package_groups

    # Find the mechanix group and get its packages
    let mechanix_packages = $package_groups | where name == "mechanix" | get packages | flatten

    # Log the list of mechanix packages
    log_debug $"Mechanix packages: ($mechanix_packages)"

    if ($mechanix_packages | length) == 0 {
        log_error "No packages found in the mechanix group"
        return
    }

    # Convert the list of packages to a space-separated string
    let packages_string = $mechanix_packages | str join " "

    # Install the mechanix packages
    log_info $"Installing mechanix packages: ($packages_string)"
    CHROOT apt-get -y --allow-change-held-packages install $packages_string

    if $env.LAST_EXIT_CODE == 0 {
        log_info "Successfully installed mechanix packages"
    } else {
        log_error "Failed to install mechanix packages"
    }
}


