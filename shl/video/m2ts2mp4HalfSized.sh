#!/usr/bin/env bash

file="$1"
shift
#ffmpegMPEG2_TSOptions="-map 0:v? -map 0:m:language:fra -b:a 96k -ar 22050 -x264-params ref=4 -movflags frag_keyframe -filter:v scale=iw/2:-1 -crf 28"
 ffmpegMPEG2_TSOptions="-map 0:v? -map 0:m:language:fra -q:a 1   -ar 22050 -x264-params ref=4 -movflags frag_keyframe -filter:v scale=iw/2:-1 -crf 28"
#ffmpegSubtitleOptions="-map 1:s? -metadata:s:s:0 language=fre -codec:s dvd_subtitle"
 ffmpegSubtitleOptions="-map 1:s? -metadata:s:s:0 language=fre -codec:s mov_text"
#for file
#do
	filePrefix="${file/.*/}"
	test -s "$filePrefix.ass" && time ffmpeg -i "$file" -i "$filePrefix.ass" $ffmpegSubtitleOptions $ffmpegMPEG2_TSOptions $@ "$filePrefix.mp4" || time ffmpeg -i "$file" $ffmpegMPEG2_TSOptions $@ "$filePrefix.mp4"
	sync
#done
