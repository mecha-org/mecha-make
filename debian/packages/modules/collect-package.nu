#!/usr/bin/env nu

use logger.nu *

export def collect_artifacts [package_name: string, source_dir: string] {
    let assets_dir = "/artifacts" | path expand
    let package_assets_dir = $"($assets_dir)/($package_name)"
    
    # Create assets directory if it doesn't exist
    if not ($assets_dir | path exists) {
        mkdir $assets_dir
    }
    
    # Create package-specific directory in assets
    if not ($package_assets_dir | path exists) {
        mkdir $package_assets_dir
    }

    log_debug $"Collecting artifacts from ($source_dir)"
    # Take absolute path of source_dir
    let abs_source_dir = (realpath $source_dir)
    log_debug $"Absolute source directory: ($abs_source_dir)"

    # Copy .deb files
    let deb_files = (ls $abs_source_dir | where name =~ '\.deb$' | get name)
    if ($deb_files | length) > 0 {
        log_debug $"Found .deb files: ($deb_files)"
        for file in $deb_files {
            log_debug $"Copying ($file) to ($package_assets_dir)"
            cp $file $package_assets_dir
        }
        
        
    } else {
        log_warn "No .deb files found to install."
    }
}