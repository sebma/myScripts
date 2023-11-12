#!/usr/bin/env bash

scriptDir=$(dirname $(readlink $0))
scriptDir=$(cd $scriptDir;pwd)
echo $PATH | grep /usr/local/bin -q || export PATH+=:/usr/local/bin
echo $PATH | grep $scriptDir -q || export PATH+=:$scriptDir
url=https://www.youtube.com/user/NewCreationChurch/live
#url="$(ytdlGetLiveURL.sh "$url")"
#cd ~/Videos/ENGLISH/CHRIST/Joseph_Prince/Live_sermons/Live_NCC/ && systemd-inhibit $scriptDir/getRestrictedFilenamesFORMAT.sh 94 "$url"
cd ~/Videos/ENGLISH/CHRIST/Joseph_Prince/Live_sermons/Live_NCC/ && getRestrictedFilenamesFORMAT.sh 94 "$url"
initPath=$(ps -p 1 -o comm= | cut -d" " -f1)
systemType=$(strings $initPath | grep -o -E "upstart|sysvinit|systemd|launchd" | head -1 || echo unknown)
test $systemType = systemd && systemctl suspend
