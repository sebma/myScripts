#!/usr/bin/env bash

function videoRemoveMetaData {
	local extension outputVideo
	local ffmpeg="command ffmpeg -hide_banner -probesize 400M -analyzeduration 400M"
	for video
	do
		extension="${video/*./}"
		outputVideo="${video/.$extension/-NoMetaData.$extension}"
		echo "=> Processing = $video ..." >&2
		$ffmpeg -i "$video" -map 0:v:0? -map 0:a? -map 0:s? -c copy -map_metadata:g -1 "$outputVideo"
		test $? = 0 && {
			touch -r "$video" "$outputVideo"
			sync
			echo >&2
			$ffprobe "$outputVideo"
		}
	done
}

videoRemoveMetaData "$@"
