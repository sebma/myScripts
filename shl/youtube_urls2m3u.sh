#!/usr/bin/env bash

if [ $# = 0 ];then
	echo "=> Usage $(basename $0) url1 url2 ..." >&2
	exit 1
fi

urls="$@"

export LANG=fr_FR.UTF-8
echo "#EXTM3U"
time echo "$urls" | tr " " "\n" | uniq | while read url
do
	printf "#EXTINF:-1,"
	\curl -Ls $url | pup 'head title text{}'
	echo $url
done
