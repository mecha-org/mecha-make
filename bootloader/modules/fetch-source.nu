#!/usr/bin/env nu

use logger.nu

export def fetch_source [repo_url: string, dest_dir: string] {
    log_info $"Checking if directory ($dest_dir) exists"

    if ( $dest_dir | path exists) {
        log_warn $"Directory ($dest_dir) already exists and is not empty"
        log_info "Skipping clone"
        return
    }

    log_info $"Cloning repository ($repo_url) to ($dest_dir)"
    git clone $repo_url $dest_dir
}