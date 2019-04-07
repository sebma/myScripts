#!/usr/bin/env bash

inputDIR="$1"
ffprobe="command ffprobe -hide_banner"
find="command find"
multiMediaFormats="3gp|aac|ac3|asf|asx|avi|divx|flv|m2t|m2ts|m4a|m4b|mkv|mov|mp2|mp3|mp4|mpeg|mpg|mts|oga|ogg|ogm|ogv|opus|pla|smil|spx|vlc|vob|wav|webm|wma|wmv|wpl|xspf"
test $inputDIR || inputDIR=.

echo "#EXTM3U"
$find "$inputDIR" -xdev -type f | \egrep "$multiMediaFormats" | sort -V | while read fileName
do
	printf "#EXTINF:-1,"
#	title=$(mediainfo --Inform="General;%Movie%" "$fileName") # 1.33 slower than ffprobe
	title=$($ffprobe -v error -show_entries format_tags=title -of default=noprint_wrappers=1:nokey=1 "$fileName")
	test $? = 0 && echo $title && echo $fileName || echo
done | sed "s|^\./||"
