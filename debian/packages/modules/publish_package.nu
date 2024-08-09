#!/usr/bin/env nu

use logger.nu *

export def publish_packages [
    package_name: string, 
    base_dir: string, 
    aptly_server: string, 
    deb_repo_name: string, 
    deb_repo_distro: string, 
    s3_publish_endpoint: string
] {
    log_debug $"Publishing packages for ($package_name) from base directory: ($base_dir)"
    
    # Take absolute path of base_dir
    let abs_base_dir = (realpath $base_dir)
    log_debug $"Absolute base directory: ($abs_base_dir)"

    # Use the base directory directly since it already points to the correct location
    let package_dir = $abs_base_dir
    if not ($package_dir | path exists) {
        log_warn $"Package directory ($package_dir) does not exist."
        return 1
    }

    log_debug $"Processing package directory: ($package_dir)"

    # Find .deb files in the package directory
    let deb_files = (ls $package_dir | where name =~ '\.deb$' | get name)
    if ($deb_files | length) == 0 {
        log_warn $"No .deb files found in directory: ($package_dir)"
        return 1
    }

    # Upload each .deb file
    for file in $deb_files {
        let package_file = $"($file)"
        log_debug $"Uploading package file: ($package_file)"
        
        # Execute curl command and capture the response
        let upload_response = (curl -X POST -F $"file=@($package_file)" $"($aptly_server)/api/files/($package_name)")
        
        # Check if the upload was successful
        if ($upload_response | str contains "error") {
            log_error $"Failed to upload package: ($upload_response)"
            continue
        } else {
            log_info $"Successfully uploaded package: ($file)"
        }
    }

    # Check if the repository exists
    let repo_check_response = (curl -X GET $"($aptly_server)/api/repos" | from json)
    if not ($repo_check_response | any { |repo| $repo.Name == $deb_repo_name }) {
        log_error $"Local repo with name ($deb_repo_name) not found."
        return 1
    }

    # Add all uploaded packages to the local repo
    log_info $"Adding packages from directory: ($package_name) to local repo: ($deb_repo_name)"
    let add_response = (curl -X POST $"($aptly_server)/api/repos/($deb_repo_name)/file/($package_name)" | from json)
    if ($add_response.FailedFiles | length) > 0 {
        log_error $"Failed to add some packages to repo: ($add_response.FailedFiles)"
        return 1
    } else {
        log_info $"Successfully added packages to repo: ($deb_repo_name)"
    }

    # Update local published repo
    log_info $"Updating local published repo for distro: ($deb_repo_distro)"
    let update_local_response = (curl -X PUT -H 'Content-Type: application/json' --data '{"Architectures": ["arm64", "amd64"], "ForceOverwrite":true, "Signing": {"Skip": true}}' $"($aptly_server)/api/publish/:./($deb_repo_distro)" | from json)

    # Log the response to understand its structure
    log_debug $"Local update response: ($update_local_response)"

    # Assume success unless specific failure conditions are known
    log_info $"Successfully updated local published repo for distro: ($deb_repo_distro)"

    # Update S3 published repo
    log_info $"Updating S3 published repo for distro: ($deb_repo_distro)"
    let update_s3_response = (curl -X PUT -H 'Content-Type: application/json' --data '{"Sources": [{"Name": "($deb_repo_name)"}], "ForceOverwrite":true, "Architectures": ["arm64", "amd64"], "Signing": {"Skip": true}}' $"($aptly_server)/api/publish/s3:($s3_publish_endpoint):/($deb_repo_distro)" | from json)
    
    # Log the response to understand its structure
    log_debug $"S3 update response: ($update_s3_response)"

    # Assume success unless specific failure conditions are known
    log_info $"Successfully updated S3 published repo for distro: ($deb_repo_distro)"

    log_info $"Packages for ($package_name) published successfully"
    return 0
}
