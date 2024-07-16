#!/usr/bin/env nu

use logger.nu

alias SUDO = sudo

const HOST_PACKAGES = "./conf-packages/host.yml"

# Function to check for and install necessary dependencies
export def check_and_install_dependencies [] {
    log_info "Checking for necessary dependencies"

    # read the required dependencies from ../conf-packages/host.yml file and store them into a list
    let required_dependencies = open $HOST_PACKAGES | get packages
    log_debug $"Required dependencies: ($required_dependencies)"
   
    # Find missing dependencies
    let missing_deps = (find_missing_dependencies $required_dependencies)
    log_debug $"Missing dependencies: ($missing_deps)"

    # Display the results
    if ($missing_deps | is-empty) {
         log_debug "All required dependencies are installed."
    } else {
           log_info "Installing missing dependencies..."
            for dep in $missing_deps {
                SUDO apt install -y $dep
            }
    }
}


def get_installed_programs [] {
    ^apt list --installed
    | lines
    | skip 1  # Skip the header line
    | parse "{package}/{version} {arch} {status}"
    | where status =~ "installed"
    | get package
}

def find_missing_dependencies [required_deps: list] {
    let installed_programs = (get_installed_programs)
    $required_deps | where { |dep| $dep not-in $installed_programs }
}