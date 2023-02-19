#!/usr/bin/env bash

scriptDir=$(dirname $0)
scriptDir=$(cd $scriptDir;pwd)
echo $PATH | grep -q $scriptDir || export PATH+=:$scriptDir
url=https://www.youtube.com/user/NewCreationChurch/live
#url="$(ytdlGetLiveURL.sh "$url")"
#cd /multimedia/Videos/CHRIST/Joseph_Prince/Live_sermons/Live_NCC/ && systemd-inhibit $scriptDir/getRestrictedFilenamesFORMAT.sh 94 "$url"
cd /multimedia/Videos/CHRIST/Joseph_Prince/Live_sermons/Live_NCC/ && getRestrictedFilenamesFORMAT.sh 94 "$url"
systemctl -i suspend
