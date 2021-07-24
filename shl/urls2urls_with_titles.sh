#!/usr/bin/env bash

function getURLTitle() {
	[ $# != 0 ] && [ "$1" = "-h" ] && {
		echo "=> Usage: $FUNCNAME url1 url2 url3 ..." >&2
		return 1
	}

	for URL
	do
#		printf "$URL # ";\curl -qLs $URL | pup --charset utf8 'title text{}' | \recode html..latin9
		printf "$URL # ";\curl -qLs $URL | pup --charset utf8 'meta[property=og:title] attr{content}' | \recode html..latin9
	done
}

getURLTitle "$@"
