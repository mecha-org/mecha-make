#!/usr/bin/env nu
use logger.nu
use os-config.nu *

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
}

export def install_host_packages [] {
    log_info "Installing host packages:"

    log_debug $"Number of packages found: (open $HOST_INSTALLATION_CONF | get packages | length)"

    open $HOST_INSTALLATION_CONF | get packages | each {|pkg| 
        # Catch and handle individual package installation failures
        try {
            install_package $pkg.name $pkg.url $pkg.sha
        } catch {|err| 
            log_error $"Failed to install package ($pkg.name): ($err)"
         
        }
    }
}

export def install_target_packages [] {
    log_info "Installing target packages:"
    
    let rootfs_dir = $env.ROOTFS_DIR
    alias CHROOT = sudo chroot $rootfs_dir

    # Clean old cache
    log_info "Cleaning old apt cache..."
    CHROOT apt-get clean

    # Retry apt-get update up to 3 times with SSL bypass
    log_info "Updating package lists..."
    let max_retries = 3
    mut retry = 0
    while ($retry < $max_retries) {
        log_debug $"Attempt ($retry + 1) for apt-get update"
        CHROOT apt-get update -o Acquire::Retries=3 -o Acquire::https::Verify-Peer=false -o Acquire::https::Verify-Host=false --allow-unauthenticated
        if $env.LAST_EXIT_CODE == 0 {
            log_info "apt-get update completed successfully"
            break
        } else {
            log_error $"apt-get update failed on attempt ($retry + 1)"
            sleep 5sec
            $retry = $retry + 1
        }
    }

    if $retry == $max_retries {
        log_error "apt-get update failed after 3 attempts. Aborting package install."
        return
    }

    # Read package groups from config
    let package_groups = open $TARGET_INSTALLATION_CONF | get package_groups

    for pkg_group in $package_groups {
        log_debug $"Processing package group: ($pkg_group.packages)"

        if ($pkg_group.packages | length) == 0 {
            log_debug "No packages found in this group. Skipping."
            continue
        }

        for pkg in $pkg_group.packages {
            try {
                log_debug $"Installing package: ($pkg)"
                CHROOT apt-get -y  --no-install-recommends --allow-change-held-packages --allow-unauthenticated install $pkg
            } catch {|err| 
                log_error $"Failed to install package ($pkg): ($err). Continuing..."
                continue
            }
        }
    }

    log_info "Target package installation complete."
    # One-time cleanup
    log_info "Cleaning apt cache after package installation..."
    CHROOT apt-get clean
}
export def add_debian_mechanix_source [] {
    let rootfs_dir = $env.ROOTFS_DIR
    alias CHROOT = sudo chroot $rootfs_dir

    let sources_list_path = "/etc/apt/sources.list"
    let keyrings_dir = "/etc/apt/keyrings"

    # Get the package source from the YAML configuration
    let build_conf_path = $env.BUILD_CONF_PATH
    let deb_package_sources = open $build_conf_path | get apt | get sources

    log_info "Adding Mechanix package sources to sources.list"

    # Ensure keyrings directory exists
    CHROOT mkdir -p $keyrings_dir

    # Iterate through each source and add it to sources.list
    $deb_package_sources | each { |source|
        let repo_url = $source.url
        let repo_key = $source.key?
        
        # Download and add GPG key if provided
        if $repo_key != null and $repo_key != "" {
            log_debug $"Downloading GPG key from: ($repo_key)"
            
            # Download key and convert to gpg format
            curl -fsSL $repo_key | CHROOT gpg --dearmor -o $"($keyrings_dir)/comet.gpg"
            
            log_info $"Added GPG key for ($repo_url)"
            
            # Add source with signed-by pointing to the key (with newline)
            let source_line = $"deb [signed-by=($keyrings_dir)/comet.gpg] ($repo_url)\n"
            log_debug $"Adding source: ($source_line)"
            printf $source_line | CHROOT tee -a $sources_list_path > /dev/null
        } else {
            # No key provided, add with trusted=yes (with newline)
            let source_line = $"deb [trusted=yes] ($repo_url)\n"
            log_debug $"Adding source: ($source_line)"
            printf $source_line | CHROOT tee -a $sources_list_path > /dev/null
        }
    }

    log_info "Successfully added all Mechanix package sources"

    log_debug "Verifying contents of sources.list:"
    CHROOT cat $sources_list_path

    # Update package lists
    log_info "Updating package lists"
    
    try {
        CHROOT apt-get update
        log_info "Successfully updated package lists"
    } catch {
        log_error "Failed to update package lists"
    }
}