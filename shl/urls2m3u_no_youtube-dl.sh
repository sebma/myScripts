#!/usr/bin/env sh

urlsFile="$1"
test $# = 0 && {
	echo "=> Usage: $(basename $0) urlsFile" >&2
	exit 1
}

echo "#EXTM3U"
egrep -v "^(#|$)" $urlsFile | \sed -E "s/#/ /;s/ +/ /g" | uniq | while read url title
do
	echo "#EXTINF:-1,$title"
	echo $url
done
