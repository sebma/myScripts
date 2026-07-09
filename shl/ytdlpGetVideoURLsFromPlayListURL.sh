#!/usr/bin/env bash

ytdlpGetVideoURLsFromPlayListURL ()
{
	local ytdlpnoconfig="yt-dlp --ignore-config"
	test $# = 0 && {
		echo "=> Usage: $FUNCNAME playListURL" 1>&2
		return 1
	}
	local playListURL="$1"
	test "$playListURL" && $ytdlpnoconfig --ignore-errors --flat-playlist -J "$playListURL" | jq -r .entries[].url
}

ytdlpGetVideoURLsFromPlayListURL "$1"
