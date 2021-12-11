#!/usr/bin/env bash

urlsFile="$1"
test $# = 0 && {
	echo "=> Usage: $(basename $0) urlsFile" >&2
	exit 1
}

echo "#EXTM3U" | \recode ..utf-8
egrep -v "^(#|$)" $urlsFile | uniq | while read line
do
	extension=.mp4
	title="$(echo $line | cut -d" " -f2- | sed "s/%20/ /g")"
	url="$(echo "$line" | sed "s/ .*//g")"
	echo "#EXTINF:-1,$title" | \recode ..utf-8
	echo $url | \recode ..utf-8
done
