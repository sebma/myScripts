#!/usr/bin/env sh

urlsFile="$1"

echo "#EXTM3U"
uniq $urlsFile | while read url
do
	printf "#EXTINF:-1,"
	\curl -Ls $url | awk -F'"' /og:title/'{print$4}'
	echo $url
done
