#!/usr/bin/env sh

inputPlaylist="$1"
ffprobe="command ffprobe -hide_banner"

echo "#EXTM3U"
awk '{print$1}' $inputPlaylist | uniq | while read fileName
do
	printf "#EXTINF:-1,"
	title=$($ffprobe -v error -show_entries format_tags=title -of default=noprint_wrappers=1:nokey=1 "$fileName")
	echo $title
	echo $fileName
done
