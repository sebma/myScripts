#!/usr/bin/env bash

scriptDir=$(dirname $0)
scriptDir=$(cd $scriptDir;pwd)
url=https://www.youtube.com/user/NewCreationChurch/live
#url="$(ytdlGetLiveURL.sh "$url")"
cd /multimedia/Videos/CHRIST/Joseph_Prince/Live_sermons/Live_NCC/ && systemd-inhibit $scriptDir/getRestrictedFilenamesFORMAT.sh 94 "$url"
systemctl -i suspend
