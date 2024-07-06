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

    let manifest = "../manifest/mecha-comet-m-gen1.yml" | path expand
    let IMX_MKIMAGE_REPO = open $manifest | get imx-mkimage | get url
    let IMX_MKIMAGE_COMMIT = open $manifest | get imx-mkimage | get commit-id

    log_debug $"Fetching IMX MKIMAGE source code from ($IMX_MKIMAGE_REPO) to ($mkimage_dir)"

    git clone $IMX_MKIMAGE_REPO $mkimage_dir
    cd $mkimage_dir
    git checkout $IMX_MKIMAGE_COMMIT
    log_info "IMX MKIMAGE build completed successfully"
    cd $work_dir
}