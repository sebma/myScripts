#!/usr/bin/env bash

#file="$1"
#shift
#set -x
for file
do
#	time avconv -i "$file" -map v:0 -map a:0 -codec:a libvo_aacenc -b:a 192k -x264-params ref=4 -crf 19 -movflags frag_keyframe "${file/.???/_HD.mp4}"
#	time avconv -i "$file" -map v:0 -map a:0 -codec:a aac -strict experimental -b:a 192k -x264-params ref=4 -crf 19 -movflags frag_keyframe "${file/.???/_HD.mp4}"
#	time ffmpeg -hide_banner -i "$file" -codec:a libfdk_aac -vbr 5 -x264-params ref=4 -crf 19 -movflags frag_keyframe -filter:v "yadif=send_frame:auto:all" "${file/.???/_HD.mp4}"
	time ffmpeg -hide_banner -i "$file" -codec:a libfdk_aac -vbr 5 -x264-params ref=4 -crf 19 -movflags frag_keyframe -filter:v yadif "${file/.???/_HD.mp4}"
	sync
done
