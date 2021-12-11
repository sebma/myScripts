#!/usr/bin/env bash

castnowURLs ()
{
	test $# = 0 && {
		echo "=> Usage: $FUNCNAME [ytdl-format] url1 url2 ..." 1>&2
		return 1
	}
	local format="mp4[height<=480]/mp4/best"
	echo $1 | \egrep -q "^(https?|s?ftps?)://" || {
		format="$1"
		shift
	}
	set -x
	for url in "$@"
	do
		LANG=C.UTF-8 command youtube-dl --no-continue --ignore-config -f "$format" -o- -- "$url" | castnow --quiet -
	done
	set +x
	echo
}

castnowURLs "$@"
