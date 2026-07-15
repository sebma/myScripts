#!/usr/bin/env bash

function ytdlpPlaylist2m3u {
	locate playListURL="$1"
	jq -r '"#EXTM3U", .entries[]? as $e | "#EXTINF:-1," + $e.title , $e.url' "$playListURL" 
}

ytdlpPlaylist2m3u "$@"
