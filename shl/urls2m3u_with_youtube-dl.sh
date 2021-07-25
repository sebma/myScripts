#!/usr/bin/env bash

urlsFile="$1"
test $# = 0 && {
	echo "=> Usage: $(basename $0) urlsFile" >&2
	exit 1
}

alias youtube-dl='LANG=C.UTF-8 command youtube-dl'

echo "#EXTM3U" | \recode ..utf-8
time awk '!/^($|#)/{print$1}' $urlsFile | uniq | while read url
do
	printf "#EXTINF:-1," | \recode ..utf-8
	youtube-dl -e $url | \recode ..utf-8
done
