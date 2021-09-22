#!/usr/bin/env bash

url=https://www.youtube.com/user/JosephPrinceOnline/live
#url="$(ytdlGetLiveURL.sh "$url")"
cd /multimedia/Videos/CHRIST/Joseph_Prince/Live_sermons_JP && getRestrictedFilenamesFORMAT.sh 93 "$url"
