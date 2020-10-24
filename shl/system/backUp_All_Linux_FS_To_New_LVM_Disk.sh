#!/usr/bin/env bash

scriptBaseName=${0##*/}
if [ $# != 1 ];then
	echo "=> $scriptBaseName destinationDisk" >&2
	exit 1
fi

destinationDisk=$1
if ! [ -b $destinationDisk ];then
	echo "[$scriptBaseName] => ERROR: <$destinationDisk> is not a block special device." >&2
	exit 2
fi

set -o errexit
set -o nounset
set -o pipefail
destinationPVPartition=$(sudo fdisk $destinationDisk -l | awk '/Linux LVM/{print$1}') || exit
set +o pipefail
#destinationVG=$(sudo pvdisplay -C $destinationPVPartition -o vg_name | awk 'END{print$1}')
destinationVG=$(sudo pvs $destinationPVPartition -o vg_name | awk 'END{print$1}')
destinationLVList=$(sudo lvs $destinationVG -o lv_name | awk 'FNR>1{print$1}' | sort -u | paste -sd' ')

df=$(which df)
fsRegExp="\<(ext[234]|btrfs|f2fs|xfs|jfs|reiserfs|nilfs|hfs|vfat|fuseblk)\>"
sourceFilesystemsList=$($df -T | egrep -vw "/media|/mnt|/tmp" | awk "/$fsRegExp/"'{print$NF}' | sort -u | paste -sd' ')
usrSourceFS=$($df /usr | awk '!/^Filesystem/{print$1}')
isLVM=$(lsblk -n $usrSourceFS -o TYPE | grep -qw lvm && echo yes || echo no)

echo "=> destinationLVList = $destinationLVList"
echo "=> isLVM = $isLVM"
echo "=> usrSourceFS = $usrSourceFS"

[ $isLVM = yes ] && sourceVG_Or_Disk=$(echo $usrSourceFS | sed "s,/dev/\|mapper.|,,g;s,[/-].*,,") || sourceVG_Or_Disk=$($df | grep /boot/efi | awk '{print gensub(".$","",1,$1)}')
echo "=> sourceVG_Or_Disk = $sourceVG_Or_Disk"

sourceEFI_FS=$(df | grep /boot/efi$ | cut -d" " -f1)
sourceEFI_UUID=$(sudo blkid $sourceEFI_FS -o value -s UUID)
destinationEFI_FS=$(sudo gdisk $destinationDisk -l | awk "/\<EFI\>/{print\"$destinationDisk\"\$1}")
destinationEFI_UUID=$(sudo blkid $destinationEFI_FS -o value -s UUID) || exit

echo "=> sourceEFI_FS = $sourceEFI_FS"
echo "=> sourceEFI_UUID = $sourceEFI_UUID"
echo "=> destinationEFI_FS = $destinationEFI_FS"
echo "=> destinationEFI_UUID = $destinationEFI_UUID"

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
sudo mount -v /dev/$destinationVG/$(echo $destinationLVList | tr " " "\n" | grep root) $destinationRootDir/ || exit
set -x
time sudo $cp2ext234 -r -x / $destinationRootDir/
set +x
sync
test -d $destinationRootDir/etc/ || sudo mkdir -v $destinationRootDir/etc/

grep -q $destinationVG $destinationRootDir/etc/fstab 2>/dev/null || sed "s/$sourceEFI_UUID/$destinationEFI_UUID/" /etc/fstab | sed "s,$sourceVG_Or_Disk,$destinationVG," | sudo tee $destinationRootDir/etc/fstab
awk '/^[^#]/{print$2}' $destinationRootDir/etc/fstab | while read dir; do test -d $destinationRootDir/$dir || sudo mkdir $destinationRootDir/$dir;done

[ -d /sys/firmware/efi ] && efiMode=true || efiMode=false
$efiMode && sudo mount -v --bind /sys/firmware/efi/efivars /mnt/sys/firmware/efi/efivars

for specialFS in dev dev/pts proc sys run ; do test -d $destinationRootDir/$specialFS/ || sudo mkdir $destinationRootDir/$specialFS/; sudo mount -v --bind /$specialFS $destinationRootDir/$specialFS ; done

sudo chroot /mnt/destinationVGDir/ findmnt >/dev/null && sudo chroot $destinationRootDir/ mount -av

echo
df -PTh | grep $destinationRootDir
echo

sourceDirList=$(echo $sourceFilesystemsList | sed "s,/ \| /$,,g")
sourceDirList="/usr"
for sourceDir in $sourceDirList
do
	destinationDir=${destinationRootDir}$sourceDir
	sourceFSType=$(mount | grep -v $destinationRootDir | grep "$sourceDir " | awk '{print$5}')
	echo "=> sourceDir = $sourceDir destinationDir = $destinationDir"
	echo "=> sourceFSType = $sourceFSType"

	case $sourceFSType in
		vfat) copyCommand="$cp2FAT32 -x";;
		ext2|ext3|ext4) copyCommand="$cp2ext234 -x";;
		*) copyCommand=echo;;
	esac

	echo
	set -x
	mount | grep -q $destinationDir && time sudo $copyCommand -r $sourceDir/ $destinationDir/
	set +x
	sync
done
sync

sudo mkdir $destinationRootDir/run
time sudo chroot $destinationRootDir/ bash -x <<-EOF
	[ -d /sys/firmware/efi ] && efiMode=true || efiMode=false
	mount | grep " / " | grep -q rw || mount -v -o remount,rw /
	grep -q "use_lvmetad\s*=\s*1" /etc/lvm/lvm.conf || sed -i "/^\s*use_lvmetad/s/use_lvmetad\s*=\s*1/use_lvmetad = 0/" /etc/lvm/lvm.conf
	update-grub
	$efiMode && efiDirectory=$(mount | awk '/\/efi /{print$3}') && grub-install --efi-directory=$efiDirectory --removable || grub-install $destinationDisk
	if which lvmetad >/dev/null 2>&1;then
		grep -q "use_lvmetad\s*=\s*0" /etc/lvm/lvm.conf || sed -i "/^\s*use_lvmetad/s/use_lvmetad\s*=\s*0/use_lvmetad = 1/" /etc/lvm/lvm.conf
	fi
	sync
EOF

sudo chroot $destinationRootDir/ umount -av
sudo umount -v $destinationRootDir/{sys/firmware/efi/efivars,sys,proc,run,dev/pts,dev,usr,}

$df | grep -q $destinationRootDir
echo "=> Restore grub in /dev/sda just in case ..."
sudo grub-install /dev/sda

echo "=> logFile = <$logFile>."
