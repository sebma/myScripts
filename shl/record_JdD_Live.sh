#!/usr/bin/env bash

estimatedDuration=150m
url=https://www.youtube.com/c/JusticedeDieuMinistry/live
#url="$(ytdlGetLiveURL.sh "$url")"
getRestrictedFilenamesFORMAT.sh --timeout $estimatedDuration 231+233 https://www.youtube.com/c/JusticedeDieuMinistry/live
