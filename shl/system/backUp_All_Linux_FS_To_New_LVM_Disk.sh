#!/usr/bin/env bash

scriptBaseName=${0##*/}
if [ $# != 1 ];then
	echo "=> $scriptBaseName destinationDisk" >&2
	exit 1
fi

set -o nounset
df=$(which df)
destinationDisk=$1
destinationPVPartition=$(sudo fdisk $destinationDisk -l | awk '/Linux LVM/{print$1}')
#destinationVG=$(sudo pvdisplay -C $destinationPVPartition -o vg_name | awk 'END{print$1}')
destinationVG=$(sudo pvs $destinationPVPartition -o vg_name | awk 'END{print$1}')
destinationLVList=$(sudo lvs $destinationVG -o lv_name | awk 'FNR>1{print$1}' | sort -u | paste -sd' ')
echo "=> destinationLVList = $destinationLVList"
fsRegExp="\<(ext[234]|btrfs|f2fs|xfs|jfs|reiserfs|nilfs|hfs|vfat|fuseblk)\>"
sourceFilesystemsList=$(df -T | egrep -vw "/media|/mnt|/tmp" | awk "/$fsRegExp/"'{print$NF}' | sort -u | paste -sd' ')
usrSourceFS=$($df /usr | awk '!/^Filesystem/{print$1}')
isLVM=$(lsblk -n $usrSourceFS -o TYPE | grep -qw lvm && echo yes || echo no)
echo "=> isLVM = $isLVM"
echo "=> usrSourceFS = $usrSourceFS"

[ $isLVM = yes ] && sourceVG_Or_Disk=$(echo $usrSourceFS | sed "s,/dev/\|mapper.|,,g;s,[/-].*,,") || sourceVG_Or_Disk=$($df | grep /boot/efi | awk '{print gensub(".$","",1,$1)}')
echo "=> sourceVG_Or_Disk = $sourceVG_Or_Disk"

sourceEFI_FS=$(df | grep /boot/efi$ | cut -d" " -f1)
sourceEFI_UUID=$(sudo blkid $sourceEFI_FS -o value -s UUID)
destinationEFI_FS=$(sudo fdisk $destinationDisk -l | awk '/\<EFI\>/{print$1}')
destinationEFI_UUID=$(sudo blkid $destinationEFI_FS -o value -s UUID)

RSYNC_SKIP_COMPRESS_LIST=7z/aac/avi/bz2/deb/flv/gz/iso/jpeg/jpg/mkv/mov/m4a/mp2/mp3/mp4/mpeg/mpg/oga/ogg/ogm/ogv/webm/rpm/tbz/tgz/z/zip
RSYNC_EXCLUSION=$(printf -- "--exclude %s/ " /dev /sys /run /proc /mnt /media)
echo "=> sourceFilesystemsList = $sourceFilesystemsList"
rsync="time $(which rsync) -x -uth -P -z --skip-compress=$RSYNC_SKIP_COMPRESS_LIST $RSYNC_EXCLUSION"
cp2ext234="$rsync -ogpuv -lSH"
cp2FAT32="$rsync --modify-window=1"
destinationDir=/mnt/destinationVGDir
test -d $destinationDir/ || sudo mkdir -v $destinationDir/
#sudo mount -v /dev/$destinationVG/$(echo $destinationLVList | grep root) $destinationDir/
#sudo $cp2ext234 -r -x / $destinationDir/
test -d $destinationDir/etc/ || sudo mkdir -v $destinationDir/etc/

grep -q $destinationVG $destinationDir/etc/fstab 2>/dev/null || sed "s/$sourceEFI_UUID/$destinationEFI_UUID/" /etc/fstab | sed "s,$sourceVG_Or_Disk,$destinationVG," | sudo tee $destinationDir/etc/fstab
