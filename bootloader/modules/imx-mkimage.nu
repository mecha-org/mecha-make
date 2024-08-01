#!/usr/bin/env nu

use logger.nu

export def build_imx_mkimage [work_dir:string] {
    log_info "Building IMX MKIMAGE"
    let mkimage_dir = ($work_dir + "/imx-mkimage") | path expand
    
    if ($mkimage_dir | path exists) {
        log_info $"IMX MKIMAGE directory already exists at ($mkimage_dir). Skipping clone and build."
        return
    }

    mkdir $mkimage_dir

    let manifest = $env.MANIFEST_DIR
    let imx_mkimage_repo = try {
        open $manifest | get deps | get imx-mkimage | get url
    } catch {
        log_error $"Failed to parse manifest file: ($manifest)"
        log_error $"($env.LAST_ERROR)"
        exit 1
    }

    let imx_mkimage_commit = try {
        open $manifest | get deps | get imx-mkimage | get commit-id
    } catch {
        log_error $"Failed to get commit-id from manifest file: ($manifest)"
        log_error $"($env.LAST_ERROR)"
        exit 1
    }

    log_debug $"Fetching IMX MKIMAGE source code from ($imx_mkimage_repo) to ($mkimage_dir)"

    git clone $imx_mkimage_repo $mkimage_dir
    cd $mkimage_dir
    git checkout $imx_mkimage_commit
    log_info "IMX MKIMAGE build completed successfully"
    cd $work_dir
}