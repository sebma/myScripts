#!/usr/bin/env bash

scriptBaseName=${0##*/}
if [ $# != 1 ];then
	echo "=> $scriptBaseName destinationDisk" >&2
	exit 1
fi

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
sudo mount -v /dev/$destinationVG/$(echo $destinationLVList | tr " " "\n" | grep root) $destinationRootDir/ || exit
set -x
time sudo $cp2ext234 -r -x / $destinationRootDir/
set +x
sync
test -d $destinationRootDir/etc/ || sudo mkdir -v $destinationRootDir/etc/

grep -q $destinationVG $destinationRootDir/etc/fstab 2>/dev/null || sed "s/$sourceEFI_UUID/$destinationEFI_UUID/" /etc/fstab | sed "s,$sourceVG_Or_Disk,$destinationVG," | sudo tee $destinationRootDir/etc/fstab
awk '/^[^#]/{print$2}' $destinationRootDir/etc/fstab | while read dir; do test -d $destinationRootDir/$dir || sudo mkdir $destinationRootDir/$dir;done

for specialFS in dev dev/pts proc sys ; do test -d $destinationRootDir/$specialFS/ || sudo mkdir $destinationRootDir/$specialFS/; sudo mount -v --bind /$specialFS $destinationRootDir/$specialFS ; done

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
time sudo chroot $destinationRootDir/ bash <<-EOF
	grep -q "use_lvmetad\s*=\s*1" /etc/lvm/lvm.conf || sed -i "/^\s*use_lvmetad/s/use_lvmetad\s*=\s*1/use_lvmetad = 0/" /etc/lvm/lvm.conf
	update-grub
	[ -d /sys/firmware/efi ] && grub-install || grub-install $destinationDisk
	if which lvmetad >/dev/null 2>&1;then
		grep -q "use_lvmetad\s*=\s*0" /etc/lvm/lvm.conf || sed -i "/^\s*use_lvmetad/s/use_lvmetad\s*=\s*0/use_lvmetad = 1/" /etc/lvm/lvm.conf
	fi
	sync
EOF

sudo chroot $destinationRootDir/ umount -av
sudo umount -v $destinationRootDir/{sys,proc,dev/pts,dev,usr,}

df | grep -q $destinationRootDir
sudo grub-install /dev/sda # Restore grub just in case

echo "=> logFile = <$logFile>."
