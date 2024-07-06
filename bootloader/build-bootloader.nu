#!/usr/bin/env nu

use modules/logger.nu *
use modules/utils.nu *
use modules/uboot-build.nu *
use modules/download-imx-firmware.nu *
use modules/arm-trusted-firmware.nu *
use modules/imx-mkimage.nu * 

# Global variables
const ARCH = "arm64"
const CROSS_COMPILE = "/usr/bin/aarch64-linux-gnu-"

# Entry point
def main [machine: string,build_dir:string] {
    log_info "Starting build script"

    # convert build_dir to absolute path
    let build_dir = $build_dir | path expand

    # let u_boot_dir = $uboot_dir
    let work_dir = $build_dir +  "/work";
    let u_boot_dir = $work_dir + "/u-boot";
    let deploy_dir = $build_dir + "/deploy";
    
    log_debug "Checking for necessary directories"
    create_dir_if_not_exist $work_dir
    create_dir_if_not_exist $deploy_dir
    create_dir_if_not_exist $u_boot_dir

    let manifest_for_machine = ($machine + ".yml")
    let manifest_dir = "../manifest/" + $manifest_for_machine | path expand

    load-env {
        ARCH: $ARCH
        CROSS_COMPILE: $CROSS_COMPILE
        WORK_DIR: $work_dir
        DEPLOY_DIR: $deploy_dir
        UBOOT_DIR: $u_boot_dir
        MANIFEST_DIR: $manifest_dir
    }

    log_info "Building U-Boot"
    build_uboot $u_boot_dir

    # building imx trusted firmware
    build_imx_trusted_firmware $work_dir

    # download and extract firmware
    download_firmware $work_dir

    # building imx mkimage
    build_imx_mkimage $work_dir

    # copy necessary files
    copy_files

    # build final image
    build_image

    # collect artifacts
    collect_artifacts $work_dir $deploy_dir

}


def copy_files [] {
    log_info "Copying necessary files to IMX MKIMAGE directory"
    let uboot_dir = $env.UBOOT_DIR
    let work_dir = $env.WORK_DIR

    # log working directory and uboot directory
    log_debug $"U-Boot directory: ($uboot_dir)"
    log_debug $"Work directory: ($work_dir)"

    let mkimage_dir = ($work_dir | path join "imx-mkimage" "iMX8M")
    cp ($uboot_dir | path join "spl" "u-boot-spl.bin") $mkimage_dir
    cp ($uboot_dir | path join "u-boot-nodtb.bin") $mkimage_dir
    cp ($uboot_dir | path join "arch" "arm" "dts" "mecha-comet.dtb") $mkimage_dir
    cp ($uboot_dir | path join "tools" "mkimage") ($mkimage_dir | path join "mkimage_uboot")
    cp ($work_dir | path join "imx-atf" "build" "imx8mm" "release" "bl31.bin") $mkimage_dir


    let synopsys_dir = ($work_dir | path join "firmware-imx" "firmware-imx-8.20" "firmware" "ddr" "synopsys")
    log_debug ($"Synopsys directory: ($synopsys_dir)")
    let pattern = ($synopsys_dir | path join "lpddr4_pmu_train_*")
    glob $pattern | each { |file| cp $file $mkimage_dir }

    cp ($mkimage_dir | path join "mecha-comet.dtb") ($mkimage_dir | path join "mecha-comet-evk.dtb")
}


def build_image [] {
    log_info "Building final image"
    let work_dir = $env.WORK_DIR
    log_debug $"Work directory: ($work_dir)"
    cd ($work_dir | path join "imx-mkimage" )
    make SOC=iMX8MM PLAT=mecha-comet flash_evk
    log_info "Image build completed successfully"
}

