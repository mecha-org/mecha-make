#!/usr/bin/env nu

use ../../modules/logger.nu *

def main [] {

    let conf = read_yml "./config.yml"
    let package = $conf | get package
    let version = $conf | get version
    let package_name = $"($package)-($version)"

    let path = $"./($package_name)" | path expand

    log_debug $"Package name: ($package_name)"

    let archive_name = $"($package)_($version).orig.tar.gz"
    # Archive the source
    archive_source $archive_name $package_name

    # Build the debian package
    build_deb_package $package_name


}


def archive_source [archive_name: string, source_dir: string] {
    log_debug $"Archiving source: ($archive_name)"
    tar -czvf $archive_name $source_dir
}

def read_yml [file: string] {
    log_info "Reading configuration file..."
    open $file;
}

def build_deb_package [package_name: string] {
    log_info $"Building debian package for ($package_name)"
    cd $package_name
    run-external debuild "-us" "-uc"
    cd ..
}

