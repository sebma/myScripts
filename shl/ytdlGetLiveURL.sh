#!/usr/bin/env bash

function ytdlGetLiveURL {
	local youtube_dl="command youtube-dl"
	local url="$1"
	set -o pipefail
	url="$($youtube_dl -j --playlist-items 1 "$url" | jq -r .webpage_url || echo "$url")"
	set +o pipefail
	echo "$url"
}

ytdlGetLiveURL "$1"
