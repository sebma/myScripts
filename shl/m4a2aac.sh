#!/usr/bin/env bash

function m4a2aac {
#	file="$1"
#	shift
	for file
	do
#		time ffmpeg -hide_banner -i "$file" -acodec copy -f adts $@ "${file/.m4a/.aac}" || continue
		time ffmpeg -hide_banner -i "$file" -acodec copy -f adts "${file/.m4a/.aac}" || continue
		touch -r "$file" "${file/.m4a/.aac}"
		sync
		\rm -v "$file"
	done
}

m4a2aac "$@"
