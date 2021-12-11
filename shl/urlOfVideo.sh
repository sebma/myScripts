#!/usr/bin/env bash

urlOfVideo ()
{
	local ffprobe="command ffprobe -hide_banner"
	local format_name=unknown
	local protocolRegExp="(https?|ftps?|s?ftp)://"
	for video in "$@"
	do
		format_name="$(videoFormat $video)"
		case $format_name in
			mov,mp4,m4a,3gp,3g2,mj2)
				tag=description
				;;
			matroska,webm)
				tag=purl
				;;
			*)
				echo "=> The $format_name is not supported yet." 1>&2 && continue
			;;
		esac
		[ $# -gt 1 ] && printf "=> video = $video\t url = "
		url=$($ffprobe -v error -show_entries format_tags=$tag -of default=noprint_wrappers=1:nokey=1 "$video" | egrep "$protocolRegExp")
		echo $url
	done
}
videoFormat ()
{
	local format_name=unknown
	for video in "$@"
	do
		$ffprobe -v error -of default=noprint_wrappers=1:nokey=1 -show_entries format=format_name "$video"
	done
}

urlOfVideo "$@"
