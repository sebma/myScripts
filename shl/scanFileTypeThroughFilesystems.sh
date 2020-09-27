#!/usr/bin/env bash

fsRegExp="\<(ext[234]|btrfs|f2fs|xfs|jfs|reiserfs|nilfs|hfs|vfat|fuseblk)\>"
RSYNC_SKIP_COMPRESS_LIST=7z/aac/avi/bz2/deb/flv/gz/iso/jpeg/jpg/mkv/mov/m4a/mp2/mp3/mp4/mpeg/mpg/oga/ogg/ogm/ogv/webm/rpm/tbz/tgz/z/zip

#sudo -k
find=$(which find)
rsync=$(which rsync)
rsyncOptions="-h -P -z --skip-compress=$RSYNC_SKIP_COMPRESS_LIST -utr"
filesystemsList=$(df -T | egrep -vw "/media|/tmp" | awk "/$fsRegExp/"'{print$NF}' | sort -u | paste -sd' ')
echo "=> filesystemsList=\"$filesystemsList\""
echo
echo "=> rsyncOptions=\"$rsyncOptions\""
echo
if sudo true;then
	time for dir in $filesystemsList
	do
		printf "=> dir = $dir "
		fsType=$(mount | grep "$dir " | awk '{print$5}')
		printf "=> fsType = <$fsType> "
		findOutput=$(sudo $find $dir -xdev -printf "%y %n %S %p\n" 2>/dev/null)
		fileTypes=$(echo "$findOutput" | cut -c1  | sort -u | tr "\n" " ")
		printf "fileTypes = $fileTypes "
		rsyncAdditionalOptions=""
		if [ "$fsType" != vfat ];then
			rsyncAdditionalOptions="-ogp"

			mount | grep $dir | grep -q acl && rsyncAdditionalOptions+=" -A"
			rsyncAdditionalOptions+=$(echo "$findOutput" | awk '$3 > 0 && $3 < 1.0 {print" -S";exit}') # File's sparseness. normally sparse files will have values less than 1.0
			rsyncAdditionalOptions+=$(echo "$findOutput" | awk '($1 == "f" && $2 > 1) {print" -H";exit}') # Number of hardlink to a file

			for fileType in $fileTypes
			do
				case $fileType in
#					b|c|p|s) echo $rsyncAdditionalOptions | grep -q "\-D" || rsyncAdditionalOptions+=" -D" ;;
					b|c) echo $rsyncAdditionalOptions | grep -q "\--devices" || rsyncAdditionalOptions+=" --devices" ;; # Cold backup : do not backup pipes'n'sockets
					d) rsyncAdditionalOptions+=" -r" ;;
					l) rsyncAdditionalOptions+=" -l" ;;
					*) ;;
				esac
			done
		else
#			rsyncAdditionalOptions+=" --size-only"
			rsyncAdditionalOptions+=" --modify-window=1" # i.e https://unix.stackexchange.com/a/461881/135038
		fi
		echo " rsyncAdditionalOptions=\"$rsyncAdditionalOptions\""
		echo
	done
fi
