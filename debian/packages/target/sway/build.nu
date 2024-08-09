#!/usr/bin/env nu

use ../../modules/install-packages.nu *
use ../../modules/collect-package.nu *
use ../../modules/logger.nu *
use ../../modules/publish_package.nu *

def read_config [] {
    open config.yml
}

def build_standard_package [package] {
    let base_version = ($package.version)
    let dir_name = $package.name
    let inner_dir_name = $"($package.name)-($base_version)"
    
    # Check if directory exists and remove it if it does
    if ($dir_name | path exists) {
        log_warn $"Directory ($dir_name) already exists. Removing it..."
        rm -rf $dir_name
    }

    # Create a directory for the package
    mkdir $dir_name
    cd $dir_name

    # Download and extract the package
    dget -u $package.url


    # List the files in the directory
    if (ls -la | length) > 0 {
        log_debug "***********Listing files in the directory*********"
        print (ls -la)
        } else {
        log_warn "No files found in the directory."
    }

    # Change to the inner directory
    cd $inner_dir_name
    if (pwd | path exists) {
        log_debug $"Changed to directory: ($inner_dir_name)"
    } else {
        log_error $"Directory ($inner_dir_name) does not exist."
        return 1
    }


    # Build the package
    if (debuild -us -uc | complete).exit_code != 0 {
        log_error $"Building package ($package.name)"
        return 1
    }



    cd ..
    # install_packages_in_directory (pwd)

    print ($env)

    # Copy .deb files to assets directory
    collect_artifacts $package.name (pwd)

    # publish the package
    publish_packages $package.name (pwd) $env.APTLY_SERVER_ENDPOINT $env.DEB_REPO_NAME $env.DEB_REPO_DISTRO $env.S3_PUBLISH_ENDPOINT
    
    cd ..

    log_info $"Done building Debian package: ($package.name)"
    return 0
}

def build_package [package] {
    match $package.build_type {
        "standard" => { build_standard_package $package }
         _ => { log_error $"Unknown build type for package ($package.name)" }
    }
}


def main [] {
    let config = read_config

    for package in $config.packages {
        log_debug $"Building package: ($package.name)"
        build_package $package
    }

    log_info "All packages built successfully"
}
