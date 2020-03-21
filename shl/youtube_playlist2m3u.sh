#!/usr/bin/env bash

if [ $# = 0 ];then
	echo "=> Usage $(basename $0) youtubePlayListURL" >&2
	exit 1
fi

youtubePlayListURL="$1"
youtubeFQDN=http://youtu.be

export LANG=fr_FR.UTF-8
echo "#EXTM3U"
time command youtube-dl --get-id $youtubePlayListURL | uniq | while read youtubeID
do
	url=$youtubeFQDN/$youtubeID
	printf "#EXTINF:-1,"
	\curl -Ls $url | awk -F'"' /og:title/'{print$4}'
	echo $url
done
