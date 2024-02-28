#!/usr/bin/env bash

echo
ffprobe="command ffprobe -hide_banner -probesize 400M -analyzeduration 400M"
movflags="+frag_keyframe"
for file
do
	extension=${file/*./}
#	audioStreamSpecifier=$($ffprobe "$file" -show_entries stream=codec_type -of flat -v 0 | awk -F "." '/="audio"/{print "0."$3".0"}')
#	time ffmpeg -hide_banner -i "$file" -map 0 -c copy -map_channel $audioStreamSpecifier -acodec aac -aq 1.5 -movflags $movflags "${file/.$extension/_MONO.$extension}" -y
	time ffmpeg -hide_banner -i "$file" -map 0 -c copy -af "pan=mono|c0=FL" -acodec aac -aq 1.5 -movflags $movflags "${file/.$extension/_MONO.$extension}" -y
	sync
	echo "=> Output File = <${file/.$extension/_MONO.$extension}>"
	echo
done
