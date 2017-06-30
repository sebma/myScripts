#!/usr/bin/env bash

#file="$1"
#shift
ffmpeg="$(which ffmpeg) -hide_banner -probesize 400M -analyzeduration 400M"
for file
do
#	time avconv  -i "$file" -acodec copy -copyts -qscale:v 0 -movflags frag_keyframe $@ "${file/.flv/.mp4}"
	time $ffmpeg -i "$file" -acodec copy -copyts -x264-params ref=4 -qscale:v 0 -movflags frag_keyframe "${file/.flv/.mp4}"
done
