#!/usr/bin/env nu
def build_error [msg: string, error?: record] {
    if ($error != null) {
        let annotated_error = ($error | upsert msg $'($msg): ($error.msg)')
        $annotated_error.rendered | print --stderr
    } else {
        (error make --unspanned { msg: $msg }) | print --stderr
    }
    exit 1
}

print "📦 Packaging release binary…"


let target = '{{ target }}'
let prime = '{{ main_package }}'
let out = "{{ output_directory }}"
let artifact_dir = $'{{ build_directory }}/($target)/release'

try {
    just build-release $target

    print $'🛬 Destination is ($out)'

    # Windows the only one that has an executable extension
    let ext = if ($target | str contains 'windows-msvc') { '.exe' } else { '' }

    # Example: package-triplet
    let qualified_name = $"($prime)-($target)"

    let bin_path = $'($artifact_dir)/($prime)($ext)' # Where rust puts the binary artifact
    let out_path = $'($out)/($qualified_name)($ext)'

    # Create output directory structure
    try {
        mkdir $out
    } catch {|e| 
        build_error $"Failed to create directory: ($out)" $e
    }

    # Copy completion scripts
    let completions = [$'($prime).bash', $'($prime).elv', $'($prime).fish', $'_($prime).ps1', $'_($prime)']

    for completion in $completions {
        let src = $'($artifact_dir)/($completion)'
        let dst = $'($out)/($completion)'

        if ($src | path exists) {
            try {
                cp --force $src $dst # Using force here because default nu copy only works with existing files otherwise
                print $"('Successfully copied completion to destination:' | ansi gradient --fgstart '0x00ff00' --fgend '0xff0080' --bgstart '0x1a1a1a' --bgend '0x0d0d0d') (basename $src)"
            } catch {|e| 
                build_error $"Failed to copy completion script ($src)" $e
            }
        } else {
            print --stderr $"Warning: completion script missing: ($src)"
        }
    }

    # Copy main binary
    try {
        cp --force $bin_path $out_path
        print $"('Successfully copied binary to destination:' | ansi gradient --fgstart '0x00ff00' --fgend '0xff0080' --bgstart '0x1a1a1a' --bgend '0x0d0d0d') (basename $bin_path)"
    } catch {  |e| 
        build_error $"Failed to copy binary ($bin_path)" $e
    }

} catch {  |e| 
    build_error "Packaging failed" $e
}
