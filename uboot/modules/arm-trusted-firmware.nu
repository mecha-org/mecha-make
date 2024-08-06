#!/usr/bin/env nu

use logger.nu
use fetch-source.nu *

export def build_imx_trusted_firmware [work_dir:string] {
    log_info "Building IMX Trusted Firmware"
    let imx_atf_dir = ($work_dir + "/imx-atf") | path expand
    mkdir $imx_atf_dir

    let manifest = $env.MANIFEST_DIR
    let imx_atf_repo = try {
        open $manifest | get deps | get imx-atf | get src
    } catch {
        log_error $"Failed to parse manifest file: ($manifest)"
        log_error $"($env.LAST_ERROR)"
        exit 1
    }

    let commit_id = try {
        open $manifest | get deps | get imx-atf | get rev
    } catch {
        log_error $"Failed to get rev from manifest file: ($manifest)"
        log_error $"($env.LAST_ERROR)"
        exit 1
    }

    let patch_file = try {
        open $manifest | get patches | get power-off
    } catch {
        log_error $"Failed to get patch file path from manifest file: ($manifest)"
        log_error $"($env.LAST_ERROR)"
        exit 1
    }

    let patch_path = $patch_file | path expand

    log_debug $"Fetching IMX Trusted Firmware source code from ($imx_atf_repo) to ($imx_atf_dir)"

    source_download $imx_atf_repo $imx_atf_dir $commit_id

    cd  $imx_atf_dir

    git apply $patch_path

    make PLAT=imx8mm bl31

    log_info "IMX Trusted Firmware build completed successfully"
    cd $work_dir
}
