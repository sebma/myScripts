#!/usr/bin/env bash

audioCodecOfFile ()
{
	local audioCodec
	local ffprobeJSON_File_Info=null
	local ffprobe="command ffprobe -hide_banner"
	for file in "$@"
	do
		ffprobeJSON_File_Info=$($ffprobe -v error -show_format -show_streams -of json "$file")
		audioCodec=$(echo $ffprobeJSON_File_Info | jq -r '[ .streams[] | select(.codec_type=="audio") ][-1].codec_name')
		printf "=> $file : audioCodec = " 1>&2
		echo $audioCodec
	done
}

audio2Video4YouTube ()
{
	test $# -ne 2 && {
		echo "=> Usage: $FUNCNAME pictureFile audioFile" 1>&2
		return 1
	}
	local ffmpeg="command ffmpeg -hide_banner"
	local pictureFile=$1
	local audioFile=$2
	local audioCodec=$(audioCodecOfFile "$audioFile" 2> /dev/null)
	local video4YouTubeFile=""
	case $audioCodec in
		aac|mp3)
			video4YouTubeFile="${audioFile%.*}__4YouTube.mp4"
			time $ffmpeg -i "$audioFile" -loop 1 -framerate 4 -i "$pictureFile" -shortest -speed max -map 0:a -c:a copy -map 1:v -preset medium -tune stillimage -crf 18 -pix_fmt yuv420p -movflags +frag_keyframe "$video4YouTubeFile"
		;;
		opus|vorbis)
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
