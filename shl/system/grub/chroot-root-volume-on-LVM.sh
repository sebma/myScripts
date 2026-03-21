#!/usr/bin/env bash

test $(id -u) == 0 && sudo="" || sudo=$(type -P sudo)
#set -o nounset
set -o errexit

$sudo lvs | grep root -q || {
	$sudo pvscan
	$sudo vgscan
	$sudo lvscan
}

currentRootFS_VG=$($sudo lvs --noheadings $(findmnt / -o source -n) -o vg_name)
rootFSLogicalVolume=$($sudo lvs | awk  "/$currentRootFS_VG/{next}"'/root/{if($2 ~ /-/){print$2"--"$1}else{print$2"-"$1}}')

set -x
mount | grep -q $rootFSLogicalVolume || $sudo mount -v /dev/mapper/$rootFSLogicalVolume /mnt
for special in dev dev/pts proc sys ; do $sudo mkdir -pv /mnt/$special;$sudo mount -v --bind /$special /mnt/$special ; done

set +o errexit
$sudo chroot /mnt bash
