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
    let kernel_version = "6.1.22mecha+"
    let kernel_build = "6"
    let target_arch = "arm64"

    # KERNELRELEASE=6.1.22-g079cc60d9b2c ARCH=arm64     KBUILD_BUILD_VERSION=2 -f

    
    # finding
    # /debs/linux-image-6.1.22mecha+_6.1.22mecha+-1_arm64.deb

    # required
    # /home/jack/Desktop/mecha/BUILD_SYSTEM_DATA/deploy/kernel/debs/linux-image-6.1.22mecha+_6.1.22mecha+-6_arm64.deb

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
