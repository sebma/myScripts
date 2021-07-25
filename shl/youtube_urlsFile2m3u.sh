#!/usr/bin/env bash

if [ $# = 0 ];then
	echo "=> Usage $(basename $0) urlsFile" >&2
	exit 1
fi

urlsFile="$1"

export LANG=fr_FR.UTF-8
echo "#EXTM3U"
time awk '{print$1}' $urlsFile | uniq | while read url
do
	printf "#EXTINF:-1,"
	\curl -Ls $url | pup 'head title text{}'
	echo $url
done
