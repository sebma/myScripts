#!/usr/bin/env bash

#file="$1"
#shift
#set -x
for file
do
	time ffmpeg -hide_banner -i "$file" -codec:a aac -q:a 1.0 -x264-params ref=4 -crf 28 -preset veryfast -movflags frag_keyframe "${file/.???/.mp4}"
	sync
done
