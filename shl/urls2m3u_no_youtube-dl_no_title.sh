#!/usr/bin/env sh

urlsFile="$1"
test $# = 0 && {
	echo "=> Usage: $(basename $0) urlsFile" >&2
	exit 1
}

echo "#EXTM3U"
#\sed -E "s/#/ /;s/ +/ /g" $urlsFile | uniq | while read url title
egrep -v "^(#|$)" $urlsFile | uniq | while read url
do
	extension=.mp4
	title=$(basename "$url" $extension | sed "s/%20/ /g")
	echo "#EXTINF:-1,$title"
	echo $url
done
