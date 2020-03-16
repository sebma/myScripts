#!/usr/bin/env bash

function getURLTitle() {
	for URL
	do
		printf "$URL # ";\curl -qLs $URL | pup --charset utf8 'title text{}' | \recode html..latin9
	done
}

getURLTitle $@
