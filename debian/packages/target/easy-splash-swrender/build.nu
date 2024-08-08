#!/usr/bin/env nu

use ../../modules/install-packages.nu *
use ../../modules/collect-package.nu *
use ../../modules/logger.nu *
use ../../modules/publish_package.nu *

def read_config [] {
    open config.yml
}


def build_custom_package [package] {
    let package_name = $package.name
    let source_url = $package.url

    let version = $package.version
    let source_dir = (pwd)

    log_info $"Building package ($package_name) ($version) from ($source_url)"

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
        cp -r $debian_source_dir debian
        log_debug $"Moved debian directory from ($debian_source_dir)"
    } else {
        log_error $"Debian source directory ($debian_source_dir) not found"
        cd $source_dir
        return 1
    }

    # Build the package
    if (debuild -us -uc | complete).exit_code != 0 {
        log_error $"Failed building package ($package_name)"
        cd $source_dir
        return 1
    }

    # Move back to the package directory
    cd ..

    # Install the built packages
    install_packages_in_directory (pwd)

    # Copy .deb files to assets directory
    collect_artifacts $package.name (pwd)


    # MECHANIX_APTLY_SERVER_ENDPOINT=http://18.227.102.140
    # MECHANIX_APTLY_DEB_REPOSITORY_NAME=mechanix-unstable # can be mechanix-stable
    # MECHANIX_APTLY_DEB_REPOSITORY_DISTRO=apollo
    # MECHANIX_APTLY_S3_PUBLISH_ENDPOINT=public-us-east-2

    let aptly_server_endpoint = "http://18.227.102.140"
    let deb_repo_name = "mechanix-deb-alpha"
    let deb_repo_distro = "apollo"
    let s3_publish_endpoint = "debian.mecha.build"

    # Publish the package
    publish_packages $package.name (pwd) $aptly_server_endpoint $deb_repo_name $deb_repo_distro $s3_publish_endpoint

    # Return to the script directory
    cd $source_dir

    log_info $"Package ($package_name) built and installed successfully"
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
        log_info $"Building package: ($package.name)"
        build_package $package
    }

    log_info "All packages built successfully"
}
