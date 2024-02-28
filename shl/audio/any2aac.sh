#!/usr/bin/env bash

#file="$1"
#shift
for file
do
#	time ffmpeg -hide_banner -i "$file" -acodec aac -aprofile aac_low -q:a 1 -f adts $@ "${file/.???/.aac}"
	time ffmpeg -hide_banner -i "$file" -acodec aac -aprofile aac_low -q:a 1 -f adts "${file/.???/.aac}"
done
