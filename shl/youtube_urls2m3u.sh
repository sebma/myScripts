#!/usr/bin/env sh

if [ $# = 0 ];then
	echo "=> Usage $(basename $0) urlsFile" >&2
	exit 1
fi

urls="$@"

export LANG=fr_FR.UTF-8
echo "#EXTM3U"
echo "$urls" | tr " " "\n" | uniq | while read url
do
	printf "#EXTINF:-1,"
	\curl -Ls $url | awk -F'"' /og:title/'{print$4}'
	echo $url
done
