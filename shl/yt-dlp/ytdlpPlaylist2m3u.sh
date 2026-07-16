#!/usr/bin/env bash

function ytdlpPlaylist2m3u {
	local playListURL="$1"
	local ytdlpnoconfig="yt-dlp --ignore-config"
	$ytdlpnoconfig --ignore-errors --flat-playlist -J "$playListURL" | jq -r '"#EXTM3U", .entries[]? as $e | "#EXTINF:" + ($e.duration | tostring) + "," + $e.title , $e.url'
}

ytdlpPlaylist2m3u "$@"
