
#!/usr/bin/env nu

use logger.nu
use fetch-source.nu



export def build_uboot [uboot_dir:string] {

    let manifest =  $env.MANIFEST_DIR

    let config = open $manifest 

    let uboot_repo = $config.src
    let machine_defconfig = $config.flags.defconfig

    log_debug $"Building U-Boot ($uboot_dir)"
    log_debug "Fetching U-Boot source code and extracting it"
    # fetch_source $uboot_repo ($uboot_dir)
    curl -L $uboot_repo | tar -xz -C ($uboot_dir) --strip-components=1

    log_info "Building U-Boot"
    cd ($uboot_dir)
    make clean

    make $machine_defconfig
    make -j (nproc)

    log_info "U-Boot build completed successfully"

    cd $uboot_dir

}