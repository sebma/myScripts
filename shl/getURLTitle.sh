#!/usr/bin/env bash

function getURLTitle() {
	for URL
	do
		\curl -qLs $URL | pup --charset utf8 'title text{}'
	done
}

getURLTitle $@
