#!/usr/bin/env bash

#set -o nounset

function videoInfo {
	local columns=$COLUMNS
#	local columns="" # To see more info than the width of the screen
	local size=0
	type -P ffprobe >/dev/null && {
		local youtube_dl='command youtube-dl'
		local ffprobe='command ffprobe -hide_banner'
		local userAgent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3513.1 Safari/537.36"
		for urlOrFile;do
			echo "=> urlOrFile = $urlOrFile"
			if echo "$urlOrFile" | egrep -q "(https?|s?ftps?|ssh|rtmp|rtsp|mms)://"
			then
				#remote stream
				streamMimeType=$(\curl -qLs --user-agent "$userAgent" "$urlOrFile" | file -bi -)
				if echo $streamMimeType | \grep "^text/" -q;then
					echo "=> This stream needs first to be resolved by youtube-dl ..."
					possibleFormats="best[ext=mp4]/best[ext=webm]/best[ext=flv]/18/webm/sd/http-480"
					infos="$($youtube_dl -gef $possibleFormats -- "$urlOrFile")"
					test -z "$infos" && continue
					title="$(echo "$infos" | sed -n 1p )"
					directURLOfStream="$(echo "$infos" | sed -n 2p)"
					size="$(\curl -qLsI --user-agent "$userAgent" "$directURLOfStream" | awk 'BEGIN{IGNORECASE=1;size=0}/Content-Length:/{if($2>0)size=$2}END{printf "%8.3f MiB\n",size/2^20}')"
					echo "Title: $title"
					echo "Size: $size"
					time $ffprobe -user_agent "$userAgent" $ffprobeOptions "$directURLOfStream" 2>&1
				elif echo $streamMimeType | \grep charset=binary -q;then
					#direct stream
					echo "=> This stream is direct stream"
					size="$(\curl -qLsI --user-agent "$userAgent" "$urlOrFile" | awk 'BEGIN{IGNORECASE=1;size=0}/Content-Length:/{if($2>0)size=$2}END{printf "%8.3f MiB\n",size/2^20}')"
					echo "Size: $size"
					time $ffprobe -user_agent "$userAgent" "$urlOrFile"
				fi
			else
				#Local file
				[ ! -s "$urlOrFile" ] && echo "=> ERROR: The file <$urlOrFile> is empty or does not exist." 1>&2 && continue
				echo "=> This file is local to this machine."
				size="$(\ls -l "$urlOrFile" | awk '/[0-9]+/{printf "%8.3f MiB\n",$5/1024^2}')"
				echo "Size: $size"
				$ffprobe "$urlOrFile" || $ffprobe $ffprobeOptions "$urlOrFile"
			fi
			echo
		done 2>&1 | \egrep -vi "^ +(:\s+$|comment|description +: [^/]+$)" | uniq | egrep --color -iw "^$|description.*:/|PURL.*:/|stream|local|urlOrFile|kb/s|Input|Size:|Title\s*:|Duration:|Channel.*:|Stream|Chapter|Invalid|error|bad| no such file|^\[.* not"
	}
}

videoInfo $@
