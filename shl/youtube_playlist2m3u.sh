#!/usr/bin/env bash

if [ $# = 0 ];then
	echo "=> Usage $(basename $0) youtubePlayListURL" >&2
	exit 1
fi

youtubePlayListURL="$1"
youtubeFQDN=http://youtu.be
ytdlnoconfig="youtube-dl --ignore-config"

export LANG=fr_FR.UTF-8
echo "#EXTM3U"
time $ytdlnoconfig --ignore-errors --flat-playlist -j "$youtubePlayListURL" | jq -r .id | uniq | while read youtubeID
do
	url=$youtubeFQDN/$youtubeID
	printf "#EXTINF:-1,"
	\curl -Ls $url | pup 'head title text{}'
	echo $url
done
