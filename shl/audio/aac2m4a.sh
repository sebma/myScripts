#!/usr/bin/env bash

aac2m4aOptions="-bsf:a aac_adtstoasc"

function aac2m4a {
#	file="$1"
#	shift
	for file
	do
#		time ffmpeg -hide_banner -i "$file" -acodec copy $aac2m4aOptions -f ipod $@ "${file/.aac/.m4a}" || continue
		time ffmpeg -hide_banner -i "$file" -acodec copy $aac2m4aOptions -f ipod "${file/.aac/.m4a}" || continue
		touch -r "$file" "${file/.aac/.m4a}"
		sync
		\rm -v "$file"
	done
}

aac2m4a "$@"
