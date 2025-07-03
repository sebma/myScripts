#!/usr/bin/env bash

ffprobe2JSON ()
{
	local ffprobe="command ffprobe -hide_banner"
	local ffprobeUserAgentOption="-user_agent \"$userAgent\""
	local ffprobeOptions="-v error -show_format -show_streams -of json"
	for arg
	do
		echo "=> arg = <$arg>." >&2
		echo "$arg" | \egrep -q "(https?|s?ftps?|ssh|rtmp|rtsp|mms)://" && $ffprobe $ffprobeUserAgentOption $ffprobeOptions "$(yt-dlp --ignore-config -g -- "$arg")" || $ffprobe $ffprobeOptions "$arg"
	done
}

ffprobe2JSON "$@"
