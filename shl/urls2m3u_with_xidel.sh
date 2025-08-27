#!/usr/bin/env bash

scriptBaseName=${0/*\//}
test $# = 0 && {
	echo "=> Usage: $scriptBaseName urlsFile" >&2
	exit 1
}

urlsFile="$1"
test -s "$urlsFile" || {
	echo "=> [$scriptBaseName] ERROR : The file <$urlsFile> does not exist or is empty" >&2
	exit 2
}

echo "#EXTM3U" | \recode ..utf-8
time awk '!/^($|#)/{print$1}' $urlsFile | uniq | while read url
do
	printf "#EXTINF:-1,"
	title=$(xidel -s --css 'title' "$url")
	echo $title
	echo $url
done
