#!/usr/bin/env bash

#file="$1"
#shift
#	time avconv -i "$file" -codec copy -copyts -movflags frag_keyframe $@ "${file/.flv/.mp4}"
for file
do
	time ffmpeg -i "$file" -codec copy "${file/.flv/.mp4}"
done
