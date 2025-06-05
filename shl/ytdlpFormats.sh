#!/usr/bin/env bash

ytdlpFormats ()
{
	trap 'rc=130;set +x;echo "=> $FUNCNAME: CTRL+C Interruption trapped.">&2;return $rc' INT
	local filterProto="\<(https?|m3u8?|dash)\>"
	test $# = 0 && {
		echo "=> Usage: $FUNCNAME [--filterFormats|-f=\"$filterProto\"] url1 url2 ..." 1>&2
		return 1
	}
	local filterFormats=""
	if echo $1 | \grep -q -- "^--filterFormats|^-f";then
		filterFormats="${1:2}"
		shift
	else
		filterFormats=$filterProto
	fi

	time yt-dlp -F "$@" | egrep -w -v "information|manifest|android player|automatic captions|Available formats|Checking .* video format URL" | \egrep "$filterFormats|Downloading"
	trap - INT
}

ytdlpFormats "$@"
