#!/usr/bin/env bash

#tmpDir=$(mktemp -d)
tmpDir=/tmp/tmp-$(id -u)
echo "=> tmpDir = $tmpDir"

mkdir -p $tmpDir 
cd $tmpDir
sfBaseUrl=http://sourceforge.net/projects/
typeset -A urlOf
urlOf[clamwin]=$sfBaseUrl/clamwin/files/latest/download
urlOf[firefox]="http://download.mozilla.org/?product=firefox-40.0-SSL&os=win&lang=fr"
urlOf[sevenzip]=$sfBaseUrl/sevenzip/files/latest/download
urlOf[smplayer]=$sfBaseUrl/smplayer/files/latest/download
urlOf[vlc]=$sfBaseUrl/vlc/files/latest/download

for tool in $(echo "${!urlOf[@]}"| tr ' ' '\n' | sort)
do
	echo "=> tool = $tool"
	url=${urlOf[$tool]}
	echo "=> url = $url"
	aria2c -o $tool-latest $url
	type=$(file -i $tool-latest | awk -F"/|;" '{print$2}')
	case $type in
	zip)	mv -v  $tool-latest $tool-latest.zip ;;
	x-xz)	mv -v $tool-latest $tool-latest.xz ;;
	x-dosexec)	mv -v $tool-latest $tool-latest.exe ;;
	x-bzip2)mv -v $tool-latest $tool-latest.bz2 ;;
	x-7z-compressed)mv -v $tool-latest $tool-latest.7z ;;
	*) ;;
	esac
done
