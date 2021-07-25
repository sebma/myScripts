#!/usr/bin/env sh

ytdlGetVideoIDsFromPlayListURL ()
{
	test $# = 0 && {
		echo "=> Usage: $FUNCNAME playListURL" 1>&2
		return 1
	}
	local ytdlnoconfig="youtube-dl --ignore-config"
	local playListURL="$1"
	test "$playListURL" && $ytdlnoconfig --ignore-errors --flat-playlist -j "$playListURL" | jq -r .id
}

ytdlGetVideoIDsFromPlayListURL "$@"
