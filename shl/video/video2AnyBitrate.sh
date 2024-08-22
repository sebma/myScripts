#!/usr/bin/env bash

ffmpeg="command ffmpeg -hide_banner"
function video2AnyBitrate {
	test $# = 0 || test $# -gt 2 && {
		echo "=> $FUNCNAME [bitrate=500k] video" 1>&2
		return 1
	}

	test $# = 1 && local bitrate=500k && local video="$1"
	test $# = 2 && local bitrate="${1/m/M}" && local video="$2"
	local ext="${video/*./}"
	local videoBaseName="${video/.*/}"

	set -x
	time $ffmpeg -i "$video" -map 0:v? -c:v:1 copy -map 0:a? -c:a copy -map 0:s? -c:s copy -map_metadata 0 -movflags use_metadata_tags -movflags +frag_keyframe -b:v:0 $bitrate "${videoBaseName}-COMPRESSED-${bitrate}bps.$ext"
	set +x
	sync
}

video2AnyBitrate "$@"
