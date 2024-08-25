#!/usr/bin/env bash

estimatedDuration=180m
scriptDir=$(dirname $(readlink -f $0))
scriptDir=$(cd $scriptDir;pwd)
echo $PATH | grep /usr/local/bin -q || export PATH+=:/usr/local/bin
echo $PATH | grep $scriptDir -q || export PATH+=:$scriptDir
url=https://www.youtube.com/user/NewCreationChurch/live
#url="$(ytdlGetLiveURL.sh "$url")"
cd ~/Videos/ENGLISH/CHRIST/Joseph_Prince/Live_sermons/Live_NCC/ && getRestrictedFilenamesFORMAT.sh --timeout $estimatedDuration -f 94/231+233 "$url"
