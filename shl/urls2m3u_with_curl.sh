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

echo "#EXTM3U"
time awk '!/^($|#)/{print$1}' $urlsFile | uniq | while read url
do
	printf "#EXTINF:-1,"
	title=$(\curl -qLs $url | pup --charset utf8 'title text{}')
	echo $title
	echo $url
done
