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

type sudo >/dev/null 2>&1 && [ $(id -u) != 0 ] && groups | egrep -wq "sudo|adm|admin|root|wheel" && sudo=$(which sudo) || sudo=""

#set -o errexit
set -o nounset
set -o pipefail

unmoutALLFSInChroot() {
	local destRootDIR="$1"
	echo "=> umounting all FS in <$destRootDIR> ..."
	sudo chroot $destRootDIR/ umount -av
	echo
	sudo umount -v $destRootDIR/{sys/firmware/efi/efivars,sys,proc,run,dev/pts,dev,usr,}
	echo
}

echo "=> Remove cache for all users ..."
\ls /home/ | grep -v lost+found | while read user
do
	sudo -u $user rm -fr /home/$user/.cache
	sudo -u $user mkdir /home/$user/.cache
done
echo

# Le "grep" est la pour forcer le code retour a "1" si il y a pas de LVM
destinationPVPartition=$(sudo fdisk $destinationDisk -l | grep 'Linux LVM' | awk '/Linux LVM/{print$1}') || exit
destinationVG=$(sudo pvs $destinationPVPartition -o vg_name | awk 'END{print$1}')
destinationLVList=$(sudo lvs $destinationVG -o lv_name | awk 'FNR>1{print$1}' | sort -u | paste -sd' ')

df=$(which df)
usrSourceFS=$(findmnt -n -c -o SOURCE /usr)
isLVM=$(lsblk -n $usrSourceFS -o TYPE | grep -qw lvm && echo yes || echo no)
if [ $isLVM = no ];then
	sourceVG_Or_Disk=$(findmnt -n -c -o SOURCE /boot/efi | sed "s/.$//")
	echo "[$scriptBaseName] => ERROR : You must use LVM." >&2
	exit 3
fi

echo "=> isLVM = $isLVM"
echo "=> usrSourceFS = $usrSourceFS"

sourceVG_Or_Disk=$(echo $usrSourceFS | awk -F"[/-]" '{print$4}')
echo "=> sourceVG_Or_Disk = $sourceVG_Or_Disk"
echo "=> destinationVG = $destinationVG"
sourceEFI_FS=$(findmnt -n -c -o SOURCE /boot/efi)
sourceEFI_UUID=$(sudo blkid $sourceEFI_FS -o value -s UUID)
# Le "grep" est la pour forcer le code retour a "1" si il y a pas de EFI
#destinationEFI_FS=$(sudo fdisk $destinationDisk -l | grep -w 'EFI' | awk "/\<EFI\>/{print\$1}") || exit
destinationEFI_FS=$(sudo gdisk $destinationDisk -l | grep -w 'EFI' | awk "/\<EFI\>/{print\"$destinationDisk\"\$1}") || exit
destinationEFI_UUID=$(sudo blkid $destinationEFI_FS -o value -s UUID) || exit

echo "=> sourceEFI_FS = $sourceEFI_FS"
echo "=> sourceEFI_UUID = $sourceEFI_UUID"
echo "=> destinationEFI_FS = $destinationEFI_FS"
echo "=> destinationEFI_UUID = $destinationEFI_UUID"

logFile="$HOME/log/completeCopy_VG_To_SSD-$(date +%Y%m%d-%HH%M).log"
echo
echo "=> logFile = <$logFile>."
echo

RSYNC_SKIP_COMPRESS_LIST=7z/aac/avi/bz2/deb/flv/gz/iso/jpeg/jpg/mkv/mov/m4a/mp2/mp3/mp4/mpeg/mpg/oga/ogg/ogm/ogv/webm/rpm/tbz/tgz/z/zip
RSYNC_EXCLUSION=$(printf -- "--exclude %s/ " /dev /sys /run /proc /mnt /media)
rsync="$(which rsync) -x -uth -P -z --skip-compress=$RSYNC_SKIP_COMPRESS_LIST $RSYNC_EXCLUSION --log-file=$logFile"

cp2ext234="$rsync -ogpuv -lSH"
cp2FAT32="$rsync --modify-window=1"

destinationRootDir=/mnt/destinationVGDir

test -d $destinationRootDir/ || sudo mkdir -v $destinationRootDir/
rootPartitionDevice=/dev/$destinationVG/$(echo $destinationLVList | tr " " "\n" | grep root)
if ! findmnt $destinationRootDir >/dev/null;then
	echo "=> Montage de la partition root dans $destinationRootDir/ ..."
	sudo mount -v $rootPartitionDevice $destinationRootDir/ || exit
fi
echo

echo "=> Copie des fichiers de la partition / dans $destinationRootDir/ ..."
time sudo $cp2ext234 -r -x / $destinationRootDir/
sync
echo

test -d $destinationRootDir/usr || sudo mkdir -v $destinationRootDir/usr
usrPartitionDevice=$(awk '/\s\/usr\s/{printf$1}' $destinationRootDir/etc/fstab)
if ! findmnt $destinationRootDir/usr >/dev/null;then
	echo "=> Montage de la partition $usrPartitionDevice  dans $destinationRootDir/usr ..."
	sudo mount -v $usrPartitionDevice $destinationRootDir/usr || exit
fi
echo

echo "=> Copie du repertoire lib de la partition /usr dans $destinationRootDir/usr ..."
time sudo $cp2ext234 -r -x /usr/lib $destinationRootDir/usr/
sync
echo

[ -d /sys/firmware/efi ] && efiMode=true || efiMode=false

grep -q $destinationVG $destinationRootDir/etc/fstab 2>/dev/null || sudo sed -i "s,$sourceVG_Or_Disk,$destinationVG," $destinationRootDir/etc/fstab
grep -q $destinationEFI_UUID $destinationRootDir/etc/fstab 2>/dev/null || sudo sed -i "s/$sourceEFI_UUID/$destinationEFI_UUID/" $destinationRootDir/etc/fstab

echo "=> Creation des points de montage dans $destinationRootDir/ ..."
awk '/^[^#]/{print substr($2,2)}' $destinationRootDir/etc/fstab | while read dir; do test -d $destinationRootDir/$dir || sudo mkdir -p -v $destinationRootDir/$dir;done

echo "=> Montage de /proc a part ..."
[ -d $destinationRootDir/proc ] || mkdir -v $destinationRootDir/proc
sudo mount -v -t proc proc $destinationRootDir/proc

echo "=> Montage de /run a part ..."
[ -d $destinationRootDir/run ] || mkdir -v $destinationRootDir/run
sudo mount -v -t tmpfs tmpfs $destinationRootDir/run

echo "=> Binding des specialFS de /dev ..."
for specialFS in dev dev/pts sys; do test -d $destinationRootDir/$specialFS/ || sudo mkdir $destinationRootDir/$specialFS/; sudo mount -v --bind /$specialFS $destinationRootDir/$specialFS ; done
$efiMode && sudo mkdir -p -v $destinationRootDir/sys/firmware/efi/efivars && sudo mount -v --bind /sys/firmware/efi/efivars $destinationRootDir/sys/firmware/efi/efivars
echo

echo "=> Montage via chroot de toutes les partitions de $destinationRootDir/etc/fstab ..."
sudo chroot $destinationRootDir/ $SHELL <<-EOF
	busybox mount -a 2>&1 >/dev/null | busybox awk '/No such file or directory/{print$5}' | busybox xargs -r mkdir -pv
EOF
echo

sourceBootDevice=$(findmnt -n -c -o SOURCE /boot)
destinationBootDevice=$(findmnt -n -c -o SOURCE $destinationRootDir/boot)
sourceRootDeviceBaseName=$(findmnt -n -c -o SOURCE / | awk -F"[/ ]" '{printf$4}')
destinationRootDeviceBaseName=$(findmnt -n -c -o SOURCE $destinationRootDir | awk -F"[/ ]" '{printf$4}')
echo "=> sourceBootDevice = $sourceBootDevice"
echo "=> destinationBootDevice = $destinationBootDevice"
echo "=> sourceRootDeviceBaseName = <$sourceRootDeviceBaseName>"
echo "=> destinationRootDeviceBaseName = <$destinationRootDeviceBaseName>"
echo

trap 'rc=127;set +x;echo "=> $scriptBaseName: CTRL+C Interruption trapped.">&2;unmoutALLFSInChroot "$destinationRootDir";exit $rc' INT

echo "=> Liste des filesystem montes dans $destinationRootDir/"
$df -PTh | grep $destinationRootDir
echo

fsRegExp="\<(ext[234]|btrfs|f2fs|xfs|jfs|reiserfs|nilfs|hfs|vfat|fuseblk)\>"
#sourceFilesystemsList=$($df -T | egrep -vw "/media|/mnt|/tmp" | awk "/$fsRegExp/"'{print$NF}' | sort -u | paste -sd' ')
sourceFilesystemsList=$($df -T | egrep -vw "/media|/mnt|/tmp|/home|/.q" | awk "/$fsRegExp/"'{print$NF}' | sort -u | paste -sd' ')
echo "=> sourceFilesystemsList = $sourceFilesystemsList"

sourceDirList=$(echo $sourceFilesystemsList | sed "s,/ \| /$,,g")
#sourceDirList="/usr"
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
	mount | grep -q $destinationDir && time sudo $copyCommand -r $sourceDir/ $destinationDir/
	echo
#	set +x
	sync
done
sync

dnsSERVER=$(host -v something.unknown | awk -F "[ #]" '/Received /{print$5}' | uniq | grep -q 127.0.0 && ( nmcli -f IP4.DNS,IP6.DNS dev list || nmcli -f IP4.DNS,IP6.DNS dev show ) 2>/dev/null | awk '/DNS/{print$NF}')

set +o nounset
srcGrubBootLVMID=$(sudo grub-probe --target=compatibility_hint --device $sourceBootDevice)
dstGrubBootLVMID=$(sudo grub-probe --target=compatibility_hint --device $destinationBootDevice)
time sudo chroot $destinationRootDir/ $SHELL <<-EOF
	set -x
	cp /etc/resolv.conf /etc/resolv.conf.back
	echo nameserver $dnsSERVER > /etc/resolv.conf
	mount | grep " / " | grep -q rw || mount -v -o remount,rw /
	grep -q "use_lvmetad\s*=\s*1" /etc/lvm/lvm.conf || sed -i "/^\s*use_lvmetad/s/use_lvmetad\s*=\s*1/use_lvmetad = 0/" /etc/lvm/lvm.conf
	update-grub
	grep -q $dstGrubBootLVMID /boot/grub/grub.cfg || sed -i "s,$srcGrubBootLVMID,$dstGrubBootLVMID,g" /boot/grub/grub.cfg
	grep -q $destinationRootDeviceBaseName /boot/grub/grub.cfg || sed -i "s,$sourceRootDeviceBaseName,$destinationRootDeviceBaseName,g" /boot/grub/grub.cfg
	[ -d /sys/firmware/efi ] && efiMode=true || efiMode=false
	$efiMode && grub-install --removable --efi-directory=$(mount | awk '/\/efi /{print$3}') || grub-install $destinationDisk
	if which lvmetad >/dev/null 2>&1;then
		grep -q "use_lvmetad\s*=\s*0" /etc/lvm/lvm.conf || sed -i "/^\s*use_lvmetad/s/use_lvmetad\s*=\s*0/use_lvmetad = 1/" /etc/lvm/lvm.conf
	fi
	sync
EOF
set -o nounset
echo

unmoutALLFSInChroot "$destinationRootDir"
trap - INT

$df -PTh | grep -q $destinationRootDir

echo "=> Restore grub in /dev/sda just in case ..."
$efiMode && efiDirectory=$(mount | awk '/\/efi /{print$3}') && sudo grub-install --efi-directory=$efiDirectory --removable || sudo grub-install /dev/sda
echo

echo "=> logFile = <$logFile>."
