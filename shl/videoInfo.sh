#!/usr/bin/env bash

#set -o nounset


function videoInfo {
	local columns=$COLUMNS
#	local columns="" # To see more info than the width of the screen
	local size=0
	which ffprobe >/dev/null && {
		local youtube_dl='command youtube-dl'
		local ffprobe='command ffprobe -hide_banner'
		for urlOrFile
		do
			echo
#			echo "=> urlOrFile = $urlOrFile"
			if echo "$urlOrFile" | egrep -q "(https?|s?ftps?|ssh|rtmp|rtsp|mms)://"
			then
				#remote stream
				if \curl -s "$urlOrFile" | file -bi - | \grep -q "^text/"
				then
					echo "=> This stream needs first to be resolved by youtube-dl ..."
					possibleFormats=best[ext=mp4]/best[ext=webm]/best[ext=flv]/18/webm/sd/http-480
					infos="$($youtube_dl -gef $possibleFormats -- "$urlOrFile")"
					test -z "$infos" && continue
					title="$(echo "$infos" | sed -n 1p )"
					directURLOfStream="$(echo "$infos" | sed -n 2p)"
					size=$(\curl -sI "$directURLOfStream" | awk 'BEGIN{IGNORECASE=1;size=0}/Content-Length:/{if($2>0)size=$2}END{printf "%8.3f MiB\n",size/2^20}')
					echo "Title: $title"
					echo "Size: $size"
					command ffprobe $ffprobeOptions "$directURLOfStream" 2>&1
				else
					#direct stream
					echo "=> This stream is direct stream"
					size=$(\curl -sI "$urlOrFile" | awk 'BEGIN{IGNORECASE=1;size=0}/Content-Length:/{if($2>0)size=$2}END{printf "%8.3f MiB\n",size/2^20}')
					echo "Size: $size"
					$ffprobe "$urlOrFile"
				fi
			else
				#Local file
				[ ! -s "$urlOrFile" ] && echo "=> ERROR: The file <$urlOrFile> is empty or does not exist." 1>&2 && continue
				echo "=> This file is local to this machine."
				size=$(\ls -l "$urlOrFile" | awk '/[0-9]+/{printf "%8.3f MiB\n",$5/1024^2}')
				echo "Size: $size"
				$ffprobe "$urlOrFile" || $ffprobe $ffprobeOptions "$urlOrFile"
			fi
		done 2>&1 | \egrep -vi "^ +(:|comment|description +: [^/]+$)" | uniq | egrep --color -iw "^$|description.*:/|PURL.*:/|stream|local|urlOrFile|kb/s|Input|Size:|Title:|Duration:|Stream|Chapter|Invalid|error|bad| no such file|^\[.* not"
	}
}

videoInfo $@
