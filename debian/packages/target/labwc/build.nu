#!/usr/bin/env nu

use ../../modules/install-packages.nu *
use ../../modules/collect-package.nu *
use ../../modules/logger.nu *
use ../../modules/publish_package.nu *

def read_config [] {
    open config.yml
}

def build_standard_package [package] {
    let base_version = ($package.version | split row "-" | first)
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
        log_debug $"(ls -la)"
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
    install_packages_in_directory (pwd)

    # Copy .deb files to assets directory
    collect_artifacts $package.name (pwd)

    # publish the package
    let aptly_server_endpoint = "http://18.227.102.140"
    let deb_repo_name = "mechanix-deb-alpha"
    let deb_repo_distro = "apollo"
    let s3_publish_endpoint = "debian.mecha.build"

    # Publish the package
    publish_packages $package.name (pwd) $aptly_server_endpoint $deb_repo_name $deb_repo_distro $s3_publish_endpoint
    
    cd ..

    log_info $"Done building Debian package: ($package.name)"
    return 0
}

def build_custom_package [package] {
    let package_name = $package.name
    let source_url = $package.url

    let version = $package.version
    let source_dir = (pwd)

    log_debug $"Building package ($package_name) ($version) from ($source_url)"

    let orig_tarball = $"($package_name)_($version).orig.tar.gz"
    let package_dir = $"($package_name)-($version)"

    # Create and enter the package directory if it doesn't exist
    if not ($package_name | path exists) {
        mkdir $package_name
    }
    cd $package_name

    # Download the source if it doesn't exist
    if not ($orig_tarball | path exists) {
        wget $source_url -O $orig_tarball
    }

    # Extract the tarball into the package_dir
    if not ($package_dir | path exists) {
        mkdir $package_dir
        tar -xvf $orig_tarball -C $package_dir --strip-components=1
    }

    # Move into the extracted directory
    cd $package_dir

    # Move the debian directory into the package
    let debian_source_dir = ($source_dir | path join $package.package_config_dir)
    if ($debian_source_dir | path exists) {
        log_debug $"Moving debian directory from ($debian_source_dir)"
        mv $debian_source_dir debian
        log_debug $"Moved debian directory from ($debian_source_dir)"
    } else {
        log_error $"Debian source directory ($debian_source_dir) not found"
        cd $source_dir
        return 1
    }

    # Build the package
    if (debuild -us -uc | complete).exit_code != 0 {
        log_warn $"Building package ($package_name)"
        cd $source_dir
        return 1
    }

    # Move back to the package directory
    cd ..

    # Install the built packages
    install_packages_in_directory (pwd)
    log_info $"Package ($package_name) built and installed successfully"
    # Copy .deb files to assets directory
    collect_artifacts $package.name (pwd)
    log_info $"Package ($package_name) artifacts collected successfully"

    # Return to the script directory
    cd $source_dir


    return 0
}


def build_package [package] {
    match $package.build_type {
        "standard" => { build_standard_package $package }
        "custom" => { build_custom_package $package }
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
