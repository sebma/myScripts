#!/usr/bin/env bash

osType=$(uname -s)
if [ $osType = Linux ];then
	grep=grep
	egrep=egrep
elif [ $osType = Darwin ];then
	grep=ggrep
	egrep="ggrep -E"
fi

wget -nv -N http://mafreebox.freebox.fr/freeboxtv/playlist.m3u
$egrep -w -B1 --no-group-separator "EXTM3U|hd" playlist.m3u > FreeBoxTV-HD.m3u
$egrep -w -B1 --no-group-separator "EXTM3U|sd" playlist.m3u > FreeBoxTV-SD.m3u
$egrep -w -B1 --no-group-separator "EXTM3U|ld" playlist.m3u > FreeBoxTV-LD.m3u
$egrep -w -B1 --no-group-separator 'EXTM3U|service=[0-9]+$' playlist.m3u > FreeBoxTV-AUTO.m3u
for file in playlist.m3u FreeBoxTV-*.m3u;do
	git diff $file | grep -w diff -q && git ci $file
done
