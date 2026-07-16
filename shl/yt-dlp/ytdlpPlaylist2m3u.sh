#!/usr/bin/env bash

function ytdlpPlaylist2m3u {
	local playListURL="$1"
	local ytdlpnoconfig="yt-dlp --ignore-config"
	local playListTitle=""
	local tmpJsonFile=$(mktemp).json
	$ytdlpnoconfig --ignore-errors --flat-playlist -J "$playListURL" > "$tmpJsonFile"
	playListTitle="$(jq -r .title "$tmpJsonFile" | sed -E "s/ /_/g;s/'/_/g;s/\|/-/g;s/[éè]/e/g" | tr -d "[:\-]")"
	playListFile="$playListTitle.m3u"
	jq -r '"#EXTM3U", .entries[]? as $e | "#EXTINF:" + ($e.duration | tostring) + "," + $e.title , $e.url' "$tmpJsonFile" | tee "$playListFile"
	echo "=> playListFile = <$playListFile>."
	rm -f "$tmpJsonFile"
}

ytdlpPlaylist2m3u "$@"
