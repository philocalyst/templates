#!/usr/bin/env nu

# Script to import external scripts according to an ad-hoc templating language

def main [path: path] {
    let base_dir = ($path | path dirname)

    open $path
    | lines
    | each {|line|
        if ($line | str contains "### IMPORT:") {
            # Example line:
            # ### IMPORT: package.nu 1 ###
            let parts  = ($line | split row " ")
            let file   = ($parts | get 2)
            let indent = ($parts | get 3 | into int)

            let tabs = (0..<$indent | each { "\t" } | str join "")

            # resolve properly relative to input file's dir
            let filepath = ($base_dir | path join $file)

            open $filepath
            | lines
            | each {|l| $tabs + $l }
            | str join (char nl)
        } else {
            $line
        }
    }
    | str join (char nl)
}
