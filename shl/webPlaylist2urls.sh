#!/usr/bin/env bash

test $# = 0 || [ $1 = -h ] && {
	echo "=> Usage ${0/*\//} playlistUrl" >&2
	exit 1
}

url="$1"
urls2urls_with_titles.sh $(extractVideoURLsFromWebPage.sh "$url" 2>/dev/null)
