#!/usr/bin/env nu

def build_package [package: record] {
    let package_name = $package.name
    let git_url = $package.git_url
    let branch = $package.branch
    let version = $package.version

    print $"Building package ($package_name) ($version) from ($git_url) on branch ($branch)"

    let orig_tarball = $"($package_name)_($version).orig.tar.gz"
    let package_dir = $"($package_name)-($version)"

    # Download source
    wget $"($git_url)/archive/refs/heads/($branch).tar.gz" -O $orig_tarball

    # makr directory with package name
    mkdir $"($package_dir)"

    # Extract source tarball with package name same as package directory
    tar -xvf $"($orig_tarball)" -C $"($package_dir)" --strip-components=1

    ls -la

    let debian_dir = "./debian" | path expand

    # Copy debian directory (assuming it's in the current directory)
    cp -r $"($debian_dir)" $"($package_dir)/debian"

    # list files in the package directory
    ls -la $"($package_dir)"

    # Build package
    cd $package_dir
    debuild -us -uc

    print $"Package ($package_name) built successfully"
}

# Main execution
def main [] {
    # Read the config file
    let packages = open ./package.yml | get packages 

    print $"==============> Found ($packages)"

    # Build each package defined in the config
    $packages | each { |pkg| build_package $pkg }
}

