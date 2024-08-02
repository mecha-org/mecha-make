#!/usr/bin/env nu

use modules/logger.nu *
use modules/pkg.nu *
use modules/utils.nu *

# Entry point
def main [machine: string,build_dir: string] {
    log_info "Starting kernel build script"

    # Read machine configuration
    let machine_config = read_yaml_config $"machines/($machine).yml"
    # Extract values from the configuration
    let kernel_repo = $machine_config.src
    let kernel_rev = $machine_config.rev
    let kernel_version = $machine_config.version
    let config_file = $"arch/($machine_config.flags.arch)/configs/($machine_config.flags.defconfig)"
    let arch = $machine_config.flags.arch
    let cross_compile = $machine_config.flags.cross_compile
    let debian_frontend = $machine_config.flags.debian_frontend

    # check_and_install_dependencies
    check_and_install_dependencies

    # Get absolute path
    let build_dir = $build_dir | path expand
    log_debug $build_dir

    let work_dir = $build_dir + "/work"
    let deploy_dir = $build_dir + "/deploy"

    # Create directories
    create_dir_if_not_exist $work_dir
    create_dir_if_not_exist $deploy_dir

    # Set environment variables
    load-env {
        BUILD_DIR: $build_dir,
        WORK_DIR: $work_dir,
        DEPLOY_DIR: $deploy_dir,
        ARCH: $arch,
        CROSS_COMPILE: $cross_compile,
        DEBIAN_FRONTEND: $debian_frontend,
        KERNEL_REPO: $kernel_repo,
        KERNEL_REV: $kernel_rev,
        CONFIG_FILE: $config_file
    }

    # Build kernel
    build_kernel

    # Build debians for kernel modules
    build_debians

    # Collect artifact
    collect_artifact

    log_info "Kernel build script completed successfully"
}

# Build Kernel
def build_kernel [] {
    log_info "Building Kernel"
    let work_dir = $env.WORK_DIR
    let linux_imx_dir = $work_dir + "/linux"

    fetch_source $env.KERNEL_REPO $linux_imx_dir

    cd $linux_imx_dir
    cp $env.CONFIG_FILE .config

    log_info "Cleaning up kernel build directory"
    make clean
    log_info "Triggering kernel Make command"
    touch .scmversion
    yes "" | make -j (nproc)
    rm .version
    make modules

    cd $work_dir
}

# Collect artifact
def collect_artifact [] {
    log_info "Collecting artifact"
    let deploy_dir = $env.DEPLOY_DIR
    let work_dir = $env.WORK_DIR
    let arch = $env.ARCH

    let artifact_path_1 = $work_dir + $"/linux/arch/($arch)/boot/Image"
    let artifact_path_2 = $work_dir + $"/linux/arch/($arch)/boot/dts/freescale/imx8mm-mecha-comet-m-gen1*"
  
    cp $artifact_path_1 $deploy_dir
        # Find and copy the second artifact(s)
    let artifact_files_2 = glob $artifact_path_2
    if ($artifact_files_2 | length) > 0 {
        $artifact_files_2 | each { |file| cp $file $deploy_dir }
    } else {
        log_error $"No artifacts found matching pattern: ($artifact_path_2)"
    }

    log_debug "Artifact collected successfully"
}

# Build debians
def build_debians [] {
    log_info "Building debian packages for kernel modules"
    let work_dir = $env.WORK_DIR
    log_debug $work_dir
    let linux_imx_dir = $work_dir + "/linux"

    cd $linux_imx_dir
    make deb-pkg -j (nproc)

    log_info "Debian packages built successfully"

    # Copy the debian packages to deploy directory
    let deploy_dir = $env.DEPLOY_DIR | path join "kernel" | path join "debs"
    create_dir_if_not_exist $deploy_dir

    log_debug $deploy_dir
    let pattern = $work_dir | path join "*.deb"
    log_debug $"Debian packages copied to deploy directory deploying to ($deploy_dir)"
    glob $pattern | each { |file| mv $file $deploy_dir }
}

# Read yaml config
def read_yaml_config [file_path: string] {
    open $file_path
}
