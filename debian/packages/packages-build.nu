#!/usr/bin/env nu

use modules/logger.nu *

def main [] {
    let config = read_config

    # Load aptly values as environment variables
    let aptly_config = $config.aptly

    print ($aptly_config)

    # Set environment variables
    load-env {
        APTLY_SERVER_ENDPOINT : $aptly_config.aptly_server_endpoint,
        DEB_REPO_NAME : $aptly_config.deb_repo_name,
        DEB_REPO_DISTRO : $aptly_config.deb_repo_distro,
        S3_PUBLISH_ENDPOINT : $aptly_config.s3_publish_endpoint
    }

    for package in $config.packages {
        build_package $package
    }

    log_info "All packages built successfully"
}


# Function to build a package
def build_package [package: string] {
    let package_dir = $"./target/($package)" | path expand
    let build_script = $"./target/($package)/build.nu" | path expand

    # Check if the package directory exists
    if ($package_dir | path exists) {
        # Check if the build script exists
        if ($build_script | path exists) {
            log_debug $"Building package: ($package)"
            cd $package_dir
            run-external nu $build_script
            log_info $"Package ($package) built successfully"
            cd ..
           
        } else {
            log_error $"Build script for ($package) not found."
        }
    } else {
        log_error $"Package directory for ($package) not found."
    }
}
# Function to read the main configuration file
def read_config [] {
    log_debug "Reading configuration file..."
    open config.yml
}