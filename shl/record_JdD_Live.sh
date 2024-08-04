#!/usr/bin/env bash

estimatedDuration=150m
url=https://www.youtube.com/c/JusticedeDieuMinistry/live
url="$(ytdlGetLiveURL.sh "$url")"
timeout -s SIGINT $estimatedDuration getRestrictedFilenamesFORMAT.sh 94/231 https://www.youtube.com/c/JusticedeDieuMinistry/live
