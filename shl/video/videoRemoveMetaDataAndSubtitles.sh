#!/usr/bin/env bash

function videoRemoveMetaDataAndSubtitles {
	local extension outputVideo
	for video
	do
		extension="${video/*./}"
		outputVideo="${video/.$extension/-NoMetaData.$extension}"
		echo "=> Processing = $video ..." >&2
		$ffmpeg -i "$video" -map 0:v:0? -map 0:a? -c copy -map_metadata:g -1 "$outputVideo"
		test $? = 0 && {
			touch -r "$video" "$outputVideo"
			sync
			echo >&2
			$ffprobe "$outputVideo"
		}
	done
}

videoRemoveMetaDataAndSubtitles "$@"
