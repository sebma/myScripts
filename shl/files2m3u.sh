#!/usr/bin/env bash

inputPlaylist="$1"
ffprobe="command ffprobe -hide_banner"

echo "#EXTM3U"
awk '{print$1}' $inputPlaylist | uniq | while read fileName
do
	printf "#EXTINF:-1,"
#	title=$(mediainfo --Inform="General;%Movie%" "$fileName") # 1.33 slower than ffprobe
	title=$($ffprobe -v error -show_entries format_tags=title -of default=noprint_wrappers=1:nokey=1 "$fileName")
	test $? = 0 && echo $title && echo $fileName || echo
done | sed "s|^\./||"
