#!/usr/bin/env bash

#set -o nounset

function videoInfo {
	youtube_dl=$(which youtube-dl)
	ffprobeOptions=""
	ffprobe=$(which ffprobe -hide_banner -probesize 400M -analyzeduration 400M)
    possibleFormats=best[ext=mp4]/best[ext=webm]/best[ext=flv]
    for urlOrFile
    do
        echo "=> urlOrFile = $urlOrFile"
        if egrep --color=auto -q "(https?|s?ftps?|ssh|rtmp|rtsp|mms)://" <<< "$urlOrFile"; then
            infos="$($youtube_dl -gef $possibleFormats "$urlOrFile")"
            test -z "$infos" && continue
            title="$(sed -n 1p <<< "$infos")"
            URL="$(sed -n 2p <<< "$infos")"
            size=$(\curl -sI "$URL" | awk 'BEGIN{IGNORECASE=1;size=0}/Content-Length:/{if($2>0)size=$2}END{printf "%8.3f MiB\n",size/2^20}')
            echo "Title: $title"
            echo "Size: $size"
            $ffprobe $ffprobeOptions "$URL" 2>&1
        else
            size=$(stat -c %s "$urlOrFile" | awk '/[0-9]+/{printf "%8.3f MiB\n",$1/1024^2}')
            echo "Size: $size"
            $ffprobe $ffprobeOptions "$urlOrFile"
        fi
    done 2>&1 | cut -c 1-$COLUMNS | egrep --color=auto -iw "urlOrFile|kb/s|Input|Size:|Title:|Duration:|Stream|Chapter|Invalid|error| no such file|^\[.* not"
}

videoInfo $@
