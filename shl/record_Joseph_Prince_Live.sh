#!/usr/bin/env bash

url=https://www.youtube.com/c/JosephPrinceOnline/live
url="$(ytdlGetLiveURL.sh "$url")"
getRestrictedFilenamesFORMAT.sh 94 https://www.youtube.com/c/JosephPrinceOnline/live
