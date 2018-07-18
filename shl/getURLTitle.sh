#!/usr/bin/env bash

function getURLTitle() {
	for URL
	do
#		youtube-dl -e $URL
		\curl -Ls $URL | awk -F'"' /og:title/'{print$4}'
	done
}

getURLTitle $@
