#!/usr/bin/env bash

echo
for file
do
	extension=${file/*./}
#	audioStreamSpecifier=$(ffprobe -hide_banner "$file" 2>&1 | sed -n "/Audio:/s/^[^0]*\|(.*//gp" | sed "s/:/./")
#	audioStreamSpecifier=$(ffprobe -hide_banner "$file" 2>&1 | awk -F " *|#|[(]" '/Audio:/{sub(":",".",$4);print$4".0"}' | sed "s/\([0-9].[0-9]\).*/\1/")
	audioStreamSpecifier=$(ffprobe "$file" -show_entries stream=codec_type -of flat -v 0 | awk -F "." '/audio/{print "0."$3".0"}')
#	time ffmpeg -hide_banner -i "$file" -map 0 -c copy -map_channel $audioStreamSpecifier -acodec aac -aq 1.0 -movflags +frag_keyframe "${file/.$extension/_MONO.$extension}" -y
	time ffmpeg -hide_banner -i "$file" -map 0 -c copy -map_channel $audioStreamSpecifier -acodec aac -aq 1.0 -movflags +faststart "${file/.$extension/_MONO.$extension}" -y
	sync
	echo "=> Output File = <${file/.$extension/_MONO.$extension}>"
	echo
done
