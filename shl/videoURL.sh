#!/usr/bin/env bash

function videoURL {
	local ffprobe="command ffprobe -hide_banner"
	for video in "$@"
	do
		printf "$video : "
		$ffprobe -v error -show_format -of json "$video" | jq '.format.tags | .description , .comment' -r | grep ^http -m1
	done
}

videoURL "$@"
