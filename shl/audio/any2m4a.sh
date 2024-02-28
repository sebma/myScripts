#!/usr/bin/env bash

#file="$1"
#shift
for file
do
#	time ffmpeg -hide_banner -i "$file" -acodec aac -aprofile aac_low -q:a 1 -f ipod $@ "${file/.???/.m4a}"
	time ffmpeg -hide_banner -i "$file" -acodec aac -aprofile aac_low -q:a 1 -f ipod "${file/.???/.m4a}"
done
