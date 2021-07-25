#!/usr/bin/env sh

urlsFile="$1"
test $# = 0 && {
	echo "=> Usage: $(basename $0) urlsFile" >&2
	exit 1
}

echo "#EXTM3U" | \recode ..utf-8
egrep -v "^(#|$)" $urlsFile | uniq | while read url
do
	extension=.mp4
	title=$(basename "$url" $extension | sed "s/%20/ /g")
	echo "#EXTINF:-1,$title" | \recode ..utf-8
	echo $url | \recode ..utf-8
done
