#!/usr/bin/env bash

function 2AudioExtension {
	local outputExtension=$(basename $BASH_SOURCE .sh)
	outputExtension=${outputExtension#?}
#   file="$1"
#   shift
#   time ffmpeg -hide_banner -i "$file" -vn -acodec copy $@ "${file%.*}.$outputExtension"
    for file
    do
        time ffmpeg -hide_banner -i "$file" -vn -acodec copy "${file%.*}.$outputExtension"
        touch -r "$file" "${file%.*}.$outputExtension"
        sync
    done
}

2AudioExtension $@
