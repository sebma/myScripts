#!/usr/bin/env sh

urlsFile="$1"

export LANG=fr_FR.UTF-8
echo "#EXTM3U"
awk '{print$1}' $urlsFile | uniq | while read url
do
	printf "#EXTINF:-1,"
	\curl -Ls $url | awk -F'"' /og:title/'{print$4}'
	echo $url
done
