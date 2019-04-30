#!/usr/bin/env sh

urlsFile="$1"
test $# = 0 && {
	echo "=> Usage: $(basename $0) urlsFile" >&2
	exit 1
}

echo "#EXTM3U"
awk '{print$1}' $urlsFile | uniq | while read url
do
	printf "#EXTINF:-1,"
	youtube-dl -e $url
#	\curl -Ls $url | awk -F'"' /og:title/'{print$4}'
	echo $url
done
