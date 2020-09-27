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
logFile="$HOME/log/completeCopy_VG_To_SSD-$(date +%Y%m%d-%HH%M).log"
echo
echo "=> logFile = <$logFile>."
echo
rsync="$(which rsync) -x -uth -P -z --skip-compress=$RSYNC_SKIP_COMPRESS_LIST $RSYNC_EXCLUSION --log-file=$logFile"
cp2ext234="$rsync -ogpuv -lSH"
cp2FAT32="$rsync --modify-window=1"
destinationRootDir=/mnt/destinationVGDir
test -d $destinationRootDir/ || sudo mkdir -v $destinationRootDir/
echo
sudo mount -v /dev/$destinationVG/$(echo $destinationLVList | tr " " "\n" | grep root) $destinationRootDir/
trap 'rc=130;set +x;echo "=> Interruption trapped, logFile = <$logFile>.">&2;exit $rc' INT
set -x
time sudo $cp2ext234 -r -x / $destinationRootDir/
trap - INT
set +x
sync
test -d $destinationRootDir/etc/ || sudo mkdir -v $destinationRootDir/etc/

grep -q $destinationVG $destinationRootDir/etc/fstab 2>/dev/null || sed "s/$sourceEFI_UUID/$destinationEFI_UUID/" /etc/fstab | sed "s,$sourceVG_Or_Disk,$destinationVG," | sudo tee $destinationRootDir/etc/fstab
sudo chroot $destinationRootDir $(which bash) -xc "mount -av"
echo
set -x
df -PTh | grep $destinationRootDir
set +x
echo

echo
for sourceDir in $(echo $sourceFilesystemsList | sed "s,/ \| /$,,g")
do
	destinationDir=${destinationRootDir}$sourceDir
	sourceFSType=$(mount | grep "$sourceDir " | awk '{print$5}')
	echo "=> sourceDir = $sourceDir destinationDir = $destinationDir"
	echo "=> sourceFSType = $sourceFSType"

	case $sourceFSType in
		vfat) copyCommand="$cp2FAT32 -x";;
		ext2|ext3|ext4) copyCommand="$cp2ext234 -x";;
	esac

	echo
#	echo "=> copyCommand = $copyCommand"
	trap 'rc=130;set +x;echo "=> Interruption trapped, logFile = <$logFile>.">&2;exit $rc' INT
#	set -x
#	$copyCommand -r $sourceDir $destinationDir/
	trap - INT
	sync
	set +x
done

for i in dev dev/pts proc sys ; do sudo mount -v --bind /$i $destinationRootDir/$i ; done
#sudo chroot $destinationRootDir/ $(which update-grub)
#sudo chroot $destinationRootDir/ $(which grub-install) $destinationDisk
sudo chroot $destinationRootDir $(which bash) -xc "umount -av"

sudo umount -v $destinationRootDir/{sys,proc,dev/pts,dev,}
echo "=> logFile = <$logFile>."
