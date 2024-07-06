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

    let manifest =  $env.MANIFEST_DIR
    let imx_mkimage_repo = open $manifest | get imx-mkimage | get url
    let imx_mkimage_commit = open $manifest | get imx-mkimage | get commit-id

    log_debug $"Fetching IMX MKIMAGE source code from ($imx_mkimage_repo) to ($mkimage_dir)"

    git clone $imx_mkimage_repo $mkimage_dir
    cd $mkimage_dir
    git checkout $imx_mkimage_commit
    log_info "IMX MKIMAGE build completed successfully"
    cd $work_dir
}