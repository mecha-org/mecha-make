#!/usr/bin/env nu

use logger.nu
use fetch-source.nu


export def download_firmware [work_dir:string] {
    log_info "Downloading and extracting firmware"

    # grab manifest file before entering the firmware directory
    let manifest =  $env.MANIFEST_DIR
    log_debug $"Fetching firmware URL from ($manifest)"
    let FIRMWARE_URL = open $manifest | get trusted-firmware | get url

    let firmware_dir = ($work_dir + "/firmware-imx")
    create_dir_if_not_exist $firmware_dir
    cd $firmware_dir

    let firmware_file = ($firmware_dir + "/firmware-imx-8.20.bin")
    if (not ($firmware_file | path exists)) {
        curl -LO $FIRMWARE_URL
        chmod a+x firmware-imx-8.20.bin
        yes | ./firmware-imx-8.20.bin | more +700
    } else {
        log_info "Firmware already downloaded. Skipping."
    }

    cd $work_dir
}

