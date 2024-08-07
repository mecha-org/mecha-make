#!/usr/bin/env nu

use logger.nu *

export def install_packages_in_directory [dir: string] {
    log_debug $"Installing packages in directory: ($dir)"
    cd $dir
    if (ls *.deb | length) > 0 {
        log_debug "Installing all .deb packages..."
        let result = (run-external "sh" "-c" "dpkg -i *.deb" | complete)
        if $result.exit_code != 0 {
            log_error $"installing packages: ($result.stderr)"
            log_warn "Attempting to resolve dependencies..."
            let apt_result = (run-external "apt-get" "install" "-f" "-y" | complete)
            if $apt_result.exit_code != 0 {
                log_error $"Failed to resolve dependencies: ($apt_result.stderr)"
            } else {
                log_info $"Successfully resolved dependencies."
            }
        } else {
            log_error $"Successfully installed all packages."
        }
    } else {
        log_warn "No .deb files found to install."
    }
    cd ..
    return 0
}