#!/usr/bin/env bash

url=https://www.youtube.com/c/JosephPrinceMinistriesUSA/live
#url="$(ytdlGetLiveURL.sh "$url")"
cd ~/Videos/ENGLISH/CHRIST/Joseph_Prince/Live_sermons/Live_JP_USA/ && getRestrictedFilenamesFORMAT.sh 230+233 "$url"
