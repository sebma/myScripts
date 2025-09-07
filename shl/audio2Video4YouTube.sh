#!/usr/bin/env bash

audio2Video4YouTube ()
{
	test $# -ne 2 && {
		echo "=> Usage: $FUNCNAME audioFile pictureFile" 1>&2
		return 1
	}
	local ffmpeg="command ffmpeg -hide_banner"
	local audioFile=$1
	local pictureFile=$2
	local audioCodec=$(audioCodecOfFile "$audioFile" 2> /dev/null)
	local video4YouTubeFile=""
	case $audioCodec in
		aac)
			video4YouTubeFile="${audioFile%.*}__4YouTube.mp4"
			time $ffmpeg -i "$audioFile" -loop 1 -framerate 4 -i "$pictureFile" -shortest -speed max -map 0:a -c:a copy -map 1:v -preset medium -tune stillimage -crf 18 -pix_fmt yuv420p -movflags +frag_keyframe "$video4YouTubeFile"
		;;
		opus | vorbis)
			video4YouTubeFile="${audioFile%.*}__4YouTube.webm"
			time $ffmpeg -i "$audioFile" -loop 1 -framerate 1 -i "$pictureFile" -shortest -speed max -map 0:a -c:a copy -map 1:v "$video4YouTubeFile"
		;;
		*)
			echo "=> ERROR : $FUNCNAME : $audioCodec is not supported yet." 1>&2
			return 1
		;;
	esac
	sync
	videoInfo "$video4YouTubeFile"
}

audio2Video4YouTube "$@"
