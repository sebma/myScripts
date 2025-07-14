#!/usr/bin/env bash

set -u
function videoLocalInfo {
	local size=0
	type -P ffprobe >/dev/null && {
		local ffprobe='command ffprobe -hide_banner'
		local ffprobeOptions="-probesize 400M -analyzeduration 400M"
		for urlOrFile;do
			echo "=> urlOrFile = $urlOrFile"
			if echo "$urlOrFile" | egrep -q "(https?|s?ftps?|ssh|rtmp|rtsp|mms)://"
			then
				#remote stream
				echo "=> Cannot handle remote stream, next ..."
				continue
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

videoLocalInfo $@
