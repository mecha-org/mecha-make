#!/usr/bin/env nu

use logger.nu
use fetch-source.nu

export def build_imx_trusted_firmware [work_dir:string] {
    log_info "Building IMX Trusted Firmware"
    let imx_atf_dir = ($work_dir + "/imx-atf") | path expand
    mkdir $imx_atf_dir

    let manifest = "../manifest/mecha-comet-m-gen1.yml" | path expand
    let IMX_ATF_REPO = open $manifest | get imx-atf | get url

    log_debug $"Fetching IMX Trusted Firmware source code from ($IMX_ATF_REPO) to ($imx_atf_dir)"
    curl -L $IMX_ATF_REPO | tar -xz -C $imx_atf_dir --strip-components=1
    cd $imx_atf_dir

    make PLAT=imx8mm bl31

    log_info "IMX Trusted Firmware build completed successfully"
    cd $work_dir
}