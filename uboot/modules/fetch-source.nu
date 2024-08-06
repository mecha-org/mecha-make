#!/usr/bin/env nu

use logger.nu

def is_git_repo [url: string] {
    $url | str ends-with ".git"
}

def download_with_git [url: string, dest: string, rev: string] {
    log_info $"Cloning git repository from ($url) to ($dest)"
    git clone $url $dest

    if ($rev | is-empty) == false {
        cd $dest
        log_info $"Checking out revision: ($rev)"
        git checkout $rev
        cd ..
    }

    log_debug "Listing files in git repository after clone:"
    print (ls -la)
}

def download_with_curl [url: string, dest: string] {
    log_info $"Downloading file from ($url) to ($dest)"
    let filename = ($url | path basename)
    curl -L $url -o $"($dest)/($filename)"
    
    log_debug "Listing files in destination directory after download:"
    print (ls -la)

    if ($url | str ends-with ".tar.gz") or ($url | str ends-with ".tgz") {
        log_info "Extracting tar.gz file"
        tar -xzvf $"($dest)/($filename)" -C $dest --strip-components=1
        rm $"($dest)/($filename)"
    } else if ($url | str ends-with ".zip") {
        log_info "Extracting zip file"
        unzip $"($dest)/($filename)" -d $dest
        rm $"($dest)/($filename)"
    } else {
        log_info "File downloaded, no extraction needed"
    }

    log_debug "Listing files in destination directory after extraction (if applicable):"
    print (ls -la)
}

export def source_download [url: string, dest: string, rev: string = ""] {
    log_info $"Checking if directory ($dest) exists"

    if (not ($dest | path exists)) {
        log_error $"Destination directory ($dest) does not exist"
        exit 1
    }

    log_debug "Listing files in destination directory before download:"
    print (ls -la)

    if (is_git_repo $url) {
        download_with_git $url $dest $rev
    } else {
        download_with_curl $url $dest
    }

    log_debug "Final listing of files in destination directory:"
    print (ls -la)
}
