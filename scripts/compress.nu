#!/usr/bin/env nu
let prime = '{{ main_package }}'
let sys = '{{ system }}'

print "🗜️ Compressing release packages..."

let dir = '{{ directory }}'
if not ($dir | path exists) {
    build_error $"Directory '($dir)' does not exist"
}

try {
    # Find all package directories
    mut package_dirs = ls $dir | where type == dir | get name

    if (($package_dirs | length) == 0) {
        # Just one package found to compress
        $package_dirs = ($package_dirs | append $dir)
    }

    for pkg_dir in $package_dirs {
        let pkg_name = ($pkg_dir | path basename)
        print $"🎁 Compressing package: ($pkg_name)"

        try {
            let parent_dir = ($pkg_dir | path dirname)
            let archive_name = $'($prime)-($sys).tar.gz'

            # Use tar command to create compressed archive
            let result = (run-external 'tar' '-czf' $archive_name '-C' $parent_dir $pkg_name | complete)

            if $result.exit_code != 0 {
                build_error $"Failed to create archive for ($pkg_name): ($result.stderr)"
            }

            print $"✅ Successfully compressed ($pkg_name)"

        } catch { |e| 
            build_error $"Compression failed for ($pkg_name)" $e
        }
    }

    print "🎉 All packages compressed successfully!"

} catch { |e| 
    build_error $"Compression process failed" $e
}
