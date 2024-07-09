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


export def create_dir_if_not_exist [dir: string] {
    let check_if_path_exists: bool =   ($dir | path exists)
    if $check_if_path_exists {
        log_debug $"Directory ($dir) already exists"
    } else {
        log_debug $"Creating directory ($dir)"
        mkdir $dir
    }
   
}