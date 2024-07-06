#!/usr/bin/env nu

use modules/logger.nu *
use modules/pkg.nu *
use modules/utils.nu *


# Variables
let arch = "arm64"
let cross_compile = "/usr/bin/aarch64-linux-gnu-"
let kernel_repo = "git@github.com:chiragp-mecha/linux-imx.git"
let config_file = "arch/arm64/configs/mecha_v8_defconfig"
let debian_frontend = "noninteractive"


# Entry point
def main [build_dir: string] {

  log_info "Starting kernel build script"

  # check_and_install_dependencies
  check_and_install_dependencies

  #  get absolute path
  let build_dir = $build_dir | path expand

  log_debug $build_dir

  let work_dir = $build_dir + "/work"
  let deploy_dir = $build_dir + "/deploy"

    ## Create directories
    create_dir_if_not_exist $work_dir
    create_dir_if_not_exist $deploy_dir

  ## Set environment variables
  load-env {
    BUILD_DIR: $build_dir,
    WORK_DIR: $work_dir,
    DEPLOY_DIR: $deploy_dir,
    ARCH: $arch,
    CROSS_COMPILE: $cross_compile,
    DEBIAN_FRONTEND : $debian_frontend
  }

    # check_and_install_dependencies
    build_kernel

    # build debians for kernel modules
    build_debians

    # collect_artifact
    log_info "Kernel build script completed successfully"
}





# Build Kernel
def build_kernel [] {
    log_info "Building Kernel"
    let work_dir = $env.WORK_DIR
    let linux_imx_dir = $work_dir + "/linux"

    fetch_source $kernel_repo $linux_imx_dir

    cd $linux_imx_dir
    cp $config_file .config

    log_info "Cleaning up kernel build directory"
    make clean
    # make manuconfig but we're using noninteractive mode
    log_info "triggering kernel Make command"
    yes "" | make -j (nproc)
    make modules

    cd $work_dir
    
}

# Collect artifact
def collect_artifact [] {
    log_info "Collecting artifact"
    let deploy_dir = $env.DEPLOY_DIR
    let work_dir = $env.WORK_DIR

    let artifact_path_1 = $work_dir + "/linux-imx/arch/$arch/boot/Image"
    let artifact_path_2 = $work_dir + "/linux-imx/arch/$arch/boot/dts/freescale/imx8mm-mecha-comet-m-gen1*"
  
    cp $artifact_path_1 $deploy_dir
    cp $artifact_path_2 $deploy_dir
    log_debug "Artifact collected successfully"
}


def build_debians [] {
    log_info "Building debian packages for kernel modules"
    let work_dir = $env.work_dir
    log_debug $work_dir
    let linux_imx_dir = $work_dir + "/linux"

    cd $linux_imx_dir
    make bindeb-pkg 

    log_info "Debian packages built successfully"

    #  we need to copy the debian packages to deploy directory the packages are built in parent directory
    let deploy_dir = $env.DEPLOY_DIR

    # in deploy dir create /kernel/debians directory and copy the debian packages
    let deploy_dir = ($deploy_dir | path join "kernel" "debs")

    create_dir_if_not_exist $deploy_dir

    log_debug $deploy_dir
    let pattern = ($work_dir | path join "*.deb")
    log_debug $"Debian packages copied to deploy directory deploying to ($deploy_dir)"
    glob $pattern | each { |file| mv $file $deploy_dir }

}