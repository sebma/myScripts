#!/usr/bin/env bash

function getURLTitle() {
	[ $# != 0 ] && [ "$1" = "-h" ] && {
		echo "=> Usage: $FUNCNAME url1 url2 url3 ..." >&2
		return 1
	}

	for URL
	do
		printf "$URL # ";\curl -qLs $URL | pup --charset utf8 'head title text{}'
	done
}

getURLTitle "$@"
