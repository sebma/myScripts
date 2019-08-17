#!/usr/bin/env bash

urlsFile="$1"
test $# = 0 && {
	echo "=> Usage: $(basename $0) urlsFile" >&2
	exit 1
}

echo "#EXTM3U"
time awk '{print$1}' $urlsFile | uniq | while read url
do
	printf "#EXTINF:-1,"
	curl -qs $url | pup --charset utf8 'title text{}'
	echo $url
done
