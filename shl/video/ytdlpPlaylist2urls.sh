#!/usr/bin/env bash

function ytdlpPlaylist2urls {
	local playListURL="$1"
	local ytdlpnoconfig="yt-dlp --ignore-config"
	$ytdlpnoconfig --ignore-errors --flat-playlist -J "$playListURL" | jq -r '.entries[]? as $e | $e.url + " # " + $e.title'
}

ytdlpPlaylist2urls "$@"
