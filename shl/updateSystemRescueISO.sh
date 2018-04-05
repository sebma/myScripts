#!/usr/bin/env bash

set -o nounset
set -o errexit

if cd /iso/gentooBased
then
	systemrescuecd=systemrescuecd-x86-latest.iso.tmp
	mkdir -p /mnt/iso ~/tmp
	rm -vf $systemrescuecd.aria2
	if aria2c -c -o $systemrescuecd http://sourceforge.net/projects/systemrescuecd/files/latest/download
	then
		if fuseiso $systemrescuecd /mnt/iso
		then
			version=$(cat /mnt/iso/version)
			echo "=> version = $version"
			rsync -aP /mnt/iso ~/tmp
			sync
			chmod u+w ~/tmp/iso
			fusermount -u /mnt/iso && mv -v systemrescuecd-x86-latest.iso.tmp systemrescuecd-x86-$version.iso
			ln -vsf systemrescuecd-x86-$version.iso systemrescuecd-x86-latest.iso
		fi
	fi
fi

