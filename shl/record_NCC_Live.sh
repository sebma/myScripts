#!/usr/bin/env bash

url=https://www.youtube.com/user/NewCreationChurch/live
#url="$(ytdlGetLiveURL.sh "$url")"
cd /multimedia/Videos/CHRIST/Joseph_Prince/Live_sermons/Live_NCC/ && getRestrictedFilenamesFORMAT.sh 94 "$url"
