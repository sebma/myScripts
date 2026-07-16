#!/usr/bin/env bash

function ytdlpPlaylist2urls {
	local playListURL="$1"
	local ytdlpnoconfig="yt-dlp --ignore-config"
	local playListTitle=""
	local tmpJsonFile=$(mktemp).json
	$ytdlpnoconfig --ignore-errors --flat-playlist -J "$playListURL" > "$tmpJsonFile"
	playListTitle="$(jq -r .title "$tmpJsonFile" | sed -E "s/ /_/g;s/'/_/g;s/\|/-/g;s/[éè]/e/g" | tr -d "[:\-]")"
	playListFile="$playListTitle.urls"
	jq -r '.entries[]? as $e | $e.url + " # " + $e.title' "$tmpJsonFile" | tee "$playListFile"
	echo "=> playListFile = <$playListFile>."
	rm -f "$tmpJsonFile"
}

ytdlpPlaylist2urls "$@"
