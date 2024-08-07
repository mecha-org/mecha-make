#!/usr/bin/env nu

def main [] {
    echo "Hello, world!"
    let path = "../bluez" | path expand

    print $"Path: ($path)"

    let conf = read_yml "./config.yml"
    echo "Configuration:"
    echo $conf

    # Accessing package and version fields from the table
    let package = $conf | get package
    let version = $conf | get version
    let package_name = $"($package)-($version)"

    echo "Package name:"
    echo $package_name

    let archive_name = $"($package)_($version).orig.tar.gz"
    # Archive the source
    archive_source $archive_name $path



  
    # Build the debian package
    build_deb_package $package_name

    # Uncomment the following line if you want to archive the source
    # archive_source "bluez.tar.gz" $path
}


def archive_source [archive_name: string, source_dir: string] {
    echo $"Archiving source: ($archive_name)"
    let temp_dir = (mktemp -d)
    cp -r $source_dir $temp_dir
    cd $temp_dir
    run-external tar "-czf" $archive_name (ls | get name | first)
    mv $archive_name $source_dir
    cd $source_dir
    rm -rf $temp_dir
}

def read_yml [file: string] {
    print "Reading configuration file..."
    open $file;
}

def build_deb_package [package_name: string] {
    echo $"Building debian package for ($package_name)"
    cd $package_name
    run-external debuild "-us" "-uc"
    cd ..
}