#!/usr/bin/env bash

type sudo >/dev/null 2>&1 && sudo="command sudo" || sudo=""
$sudo -v

test $# = 0 && fileSystemList=$(df -T | egrep -iv "home|data" | awk "/btrfs|ext[234]/"'{print$NF}') || fileSystemList=$@

for fileSystem in $fileSystemList
do
	echo "=> fileSystem = $fileSystem"
	$sudo find $fileSystem -xdev -printf "%M\n" 2>/dev/null | cut -c1  | sort -u
	echo "==> Inode (hardlinks) :"
	$sudo find $fileSystem -xdev -printf "%n %p\n" 2>/dev/null | grep "^[3-9] "
done
