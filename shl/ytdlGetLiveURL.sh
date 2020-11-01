#!/usr/bin/env bash

youtube_dl=$(which youtube-dl)
url="$1"
#url="$($youtube_dl --get-filename -o '%(webpage_url)s' --playlist-items 1 "$url")"
echo "$url"
