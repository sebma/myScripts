#!/usr/bin/env bash

function videoURL {
	local ffprobe="command ffprobe -hide_banner"
	for video in "$@"
	do
		printf "$video : "
		$ffprobe "$video" 2>&1 | awk '/PURL|description/{print$3;exit;}'
	done
}

videoURL "$@"
