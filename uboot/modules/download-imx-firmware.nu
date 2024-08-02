#!/usr/bin/env nu

use logger.nu
use fetch-source.nu


export def download_firmware [work_dir:string] {
    log_info "Downloading and extracting firmware"

  # grab manifest file before entering the firmware directory
    let manifest = $env.MANIFEST_DIR
    log_debug $"Fetching firmware URL from ($manifest)"
    let firmware_url = try {
        open $manifest | get deps | get trusted-firmware | get url
    } catch {
        log_error $"Failed to parse manifest file: ($manifest)"
        log_error $"($env.LAST_ERROR)"
        exit 1
    }

    let firmware_dir = ($work_dir + "/firmware-imx")
    create_dir_if_not_exist $firmware_dir
    cd $firmware_dir
    log_debug $"moving to firmware directory: ($firmware_dir)"

    let firmware_file = ($firmware_dir + "/firmware-imx-8.20.bin")
    if (not ($firmware_file | path exists)) {
        curl -LO $firmware_url
        log_debug $"Firmware downloaded to ($firmware_file)"
        chmod a+x firmware-imx-8.20.bin
        log_debug "Installing firmware"
        # workaround for the firmware installer that requieres accepting the license
        yes | ./firmware-imx-8.20.bin | more +1000
    } else {
        log_info "Firmware already downloaded. Skipping."
    }

    cd $work_dir
}

