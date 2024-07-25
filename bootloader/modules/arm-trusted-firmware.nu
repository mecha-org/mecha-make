#!/usr/bin/env nu

use logger.nu
use fetch-source.nu

export def build_imx_trusted_firmware [work_dir:string] {
    log_info "Building IMX Trusted Firmware"
    let imx_atf_dir = ($work_dir + "/imx-atf") | path expand
    mkdir $imx_atf_dir

    let manifest =  $env.MANIFEST_DIR
    let IMX_ATF_REPO = open $manifest | get imx-atf | get url

    let patch_path =   (open $manifest  | get patch-path)
    let patch_path = $patch_path | path expand

    log_debug $"Fetching IMX Trusted Firmware source code from ($IMX_ATF_REPO) to ($imx_atf_dir)"

#    curl -L $IMX_ATF_REPO | tar -xz -C $imx_atf_dir --strip-components=1

    git clone $IMX_ATF_REPO $imx_atf_dir

    cd $imx_atf_dir

    git checkout 99195a23d3aef485fb8f10939583b1bdef18881c

    git apply $"($patch_path)/0001-resolve-poweroff-issue.patch"

    make PLAT=imx8mm bl31

    log_info "IMX Trusted Firmware build completed successfully"
    cd $work_dir
}