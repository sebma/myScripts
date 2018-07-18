#!/usr/bin/env bash

function getURLTitle() {
	for URL
	do
		youtube-dl -e $URL
#		\cURL -Ls $url | awk -F'"' /og:title/'{print$4}'
	done
}

getURLTitle $@
