#!/usr/bin/env sh

youtubePlayList="$1"
youtubeFQDN=http://youtu.be

export LANG=fr_FR.UTF-8
echo "#EXTM3U"
command youtube-dl --get-id $youtubePlayList | uniq | while read youtubeID
do
	url=$youtubeFQDN/$youtubeID
	printf "#EXTINF:-1,"
	\curl -Ls $url | awk -F'"' /og:title/'{print$4}'
	echo $url
done
