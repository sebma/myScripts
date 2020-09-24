#!/usr/bin/env bash

fsRegExp="ext[234]|btrfs|f2fs|xfs|jfs|reiserfs|nilfs|hfs|vfat|fuseblk|devtmpfs|tmpfs"
RSYNC_SKIP_COMPRESS_LIST=7z/aac/avi/bz2/deb/flv/gz/iso/jpeg/jpg/mkv/mov/m4a/mp2/mp3/mp4/mpeg/mpg/oga/ogg/ogm/ogv/webm/rpm/tbz/tgz/z/zip

sudo -k
find=$(which find)
if sudo true;then
	time for dir in $(df -T | egrep -v "/media/|/dev/sd[b-z]" | awk "/$fsRegExp/"'{print$NF}' | egrep -vw "/home|/tmp" | sort -u)
	do
		printf "=> dir = $dir "
		fileTypes=$(time sudo $find $dir -xdev -printf "%M\n" 2>/dev/null | cut -c1  | sort -u | tr "\n" " ")
		printf "fileTypes = $fileTypes "
		rsyncOptions="-h -P -z --skip-compress=$RSYNC_SKIP_COMPRESS_LIST -ut -pgo"
		rsyncAdditionalOptions=""
		mount | grep $dir | grep -q acl && rsyncAdditionalOptions+=" -A"
		time sudo find $dir -xdev -type f -printf "%S\t%p\n" 2>/dev/null | awk '$1 < 1.0 {print"sparseFile : "$2}' | grep -m1 -i -q sparseFile && rsyncAdditionalOptions+=" -S"
		time sudo find $dir -xdev -printf "%n %p\n" 2>/dev/null | grep -m1 -q "^[3-9] " && rsyncAdditionalOptions+=" -H"

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
