#!/usr/bin/env bash

function getURLTitle() {
	if type -P pup > /dev/null; then
		for URL
		do
			printf "$URL # "
			\curl -qLs $URL | pup --charset utf8 'head title text{}'
		done
	elif type -P xidel > /dev/null; then
		for URL
		do
			printf "$URL # "
			\curl -qLs $URL | xidel -s --css 'head title'
		done
	elif type -P hxselect > /dev/null; then
		for URL
		do
			printf "$URL # "
			\curl -qLs $URL | hxnormalize -x | hxselect -s '\n' 'head title' -c
		done
	fi
}

getURLTitle $@
