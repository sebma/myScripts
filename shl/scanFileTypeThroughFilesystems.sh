#!/usr/bin/env bash

fsRegExp="\<(ext[234]|btrfs|f2fs|xfs|jfs|reiserfs|nilfs|hfs|vfat|fuseblk|devtmpfs)\>"
RSYNC_SKIP_COMPRESS_LIST=7z/aac/avi/bz2/deb/flv/gz/iso/jpeg/jpg/mkv/mov/m4a/mp2/mp3/mp4/mpeg/mpg/oga/ogg/ogm/ogv/webm/rpm/tbz/tgz/z/zip

#sudo -k
find=$(which find)
rsync=$(which rsync)
rsyncOptions="-h -P -z --skip-compress=$RSYNC_SKIP_COMPRESS_LIST -ut -pgo -r"
if sudo true;then
	time for dir in $(df -T | egrep -v "/media/|/dev/sd[b-z]" | awk "/$fsRegExp/"'{print$NF}' | egrep -vw "/home|/tmp" | sort -u)
	do
		printf "=> dir = $dir "
		findOutput=$(sudo $find $dir -xdev -printf "%M %n %S %p\n" 2>/dev/null | awk '{$1=substr($1,1,1);print}')

		fileTypes=$(echo "$findOutput" | cut -c1  | sort -u | tr "\n" " ")
		printf "fileTypes = $fileTypes "

		rsyncAdditionalOptions=""
		mount | grep $dir | grep -q acl && rsyncAdditionalOptions+=" -A"
		echo
		rsyncAdditionalOptions+=$(echo "$findOutput" | awk '$3 > 0 && $3 < 1.0 {print" -S";exit}') # File's sparseness. normally sparse files will have values less than 1.0
		rsyncAdditionalOptions+=$(echo "$findOutput" | awk '$2 > 1 && /^-/ {print" -H";print>"/dev/stderr";exit}') # Number of hardlink to a file

		for type in $fileTypes
		do
			case $type in
				b|c|p|s) rsyncAdditionalOptions+=" -D" ;;
				d) rsyncAdditionalOptions+=" -r" ;;
				l) rsyncAdditionalOptions+=" -l" ;;
				*) ;;
			esac
		done
		echo "rsyncAdditionalOptions = $rsyncAdditionalOptions"
		echo
	done
fi
