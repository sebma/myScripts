#!/usr/bin/env bash

#file="$1"
#shift
for file
do
#	time ffmpeg -hide_banner -i "$file" -acodec aac -aprofile aac_high -q:a 1 -f ipod $@ "${file/.???/.m4a}"
	time ffmpeg -hide_banner -i "$file" -acodec libfdk_aac -aprofile aac_he_v2 -vbr 1 -f ipod "${file/.???/_HE-AACv2.m4a}"
done
