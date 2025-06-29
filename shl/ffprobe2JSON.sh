#!/usr/bin/env bash

ffprobe2JSON ()
{
	local ffprobe="command ffprobe -hide_banner"
	local ffprobeUserAgentOption="-user_agent \"$userAgent\""
	local ffprobeOptions="-v error -show_format -show_streams -of json"
	for arg in "$@"
	do
		echo "$arg" | \egrep -q "(https?|s?ftps?|ssh|rtmp|rtsp|mms)://" && $ffprobe $ffprobeUserAgentOption $ffprobeOptions "$(yt-dlp --ignore-config -g -- "$arg")" || $ffprobe $ffprobeOptions "$arg"
#	done 2>&1 | cut -c 1-$(tput cols)
	done
}

ffprobe2JSON "$@"
