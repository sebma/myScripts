#!/usr/bin/env bash

scriptBaseName=${0##*/}
logFile="$HOME/log/$scriptBaseName-$(date +%Y%m%d-%HH%M).log"

if [ $# != 1 ];then
	echo "=> $scriptBaseName destinationDisk" >&2
	echo "=> $scriptBaseName destinationDisk" | tee -a "$logFile"
	exit 1
fi

destinationDisk=$1
if ! [ -b $destinationDisk ];then
	echo "[$scriptBaseName] => ERROR: <$destinationDisk> is not a block special device." >&2
	echo "[$scriptBaseName] => ERROR: <$destinationDisk> is not a block special device." | tee -a "$logFile"
	exit 2
fi

df=$(which df)
type sudo >/dev/null 2>&1 && [ $(id -u) != 0 ] && groups | egrep -wq "sudo|adm|admin|root|wheel" && sudo=$(which sudo) || sudo=""

#set -o errexit
set -o nounset
set -o pipefail

unmoutALLFSInDestination() {
	local destRootDIR="$1"
	echo "=> Syncing data ..."
	sync
	echo "=> umounting all FS in <$destRootDIR> ..."
	[ -f $destRootDIR$(which chroot) ] && $sudo chroot $destRootDIR/ umount -av
	echo
	$sudo umount -v $destRootDIR/{sys/firmware/efi/efivars,sys,proc,run,dev/pts,dev,usr,}
	echo
}

echo "=> Remove cache for all users ..."
\ls /home/ | grep -v lost+found | while read user
do
	$sudo rm -fr /home/$user/.cache
	$sudo -u $user mkdir /home/$user/.cache
done | tee -a "$logFile"
echo "=> Done."

# Le "grep" est la pour forcer le code retour a "1" si il y a pas de LVM
destinationPVPartition=$($sudo fdisk $destinationDisk -l | grep 'Linux LVM' | awk '/Linux LVM/{print$1}') || exit
destinationVG=$($sudo \pvs $destinationPVPartition -o vg_name --noheadings | awk '{printf$1}')
destinationLVList=$($sudo \lvs $destinationVG -o lv_name --noheadings --sort lv_name | awk '{printf$1" "}')

usrSourceFS=$(findmnt -n -c -o SOURCE /usr)
isLVM=$(lsblk -n $usrSourceFS -o TYPE | grep -qw lvm && echo yes || echo no)
if [ $isLVM = no ];then
	echo "[$scriptBaseName] => ERROR : You must use LVM." >&2
	echo "[$scriptBaseName] => ERROR : You must use LVM." | tee -a "$logFile"
	exit 3
fi

sourceVG=$(sudo \lvs --noheadings -o vg_name $usrSourceFS | awk '{printf$1}')

{
echo "=> isLVM = $isLVM"
echo "=> usrSourceFS = $usrSourceFS"
echo "=> sourceVG = $sourceVG"
echo "=> destinationVG = $destinationVG"
} | tee -a "$logFile"

[ -d /sys/firmware/efi ] && efiMode=true || efiMode=false
if $efiMode;then
	sourceEFI_FS=$(findmnt -n -c -o SOURCE /boot/efi)
	sourceEFI_UUID=$($sudo blkid $sourceEFI_FS -o value -s UUID)
	# Le "grep" est la pour forcer le code retour a "1" si il y a pas de EFI
	#destinationEFI_FS=$($sudo fdisk $destinationDisk -l | grep -w 'EFI' | awk "/\<EFI\>/{print\$1}") || exit
	destinationEFI_FS=$($sudo gdisk $destinationDisk -l | grep -w 'EFI' | awk "/\<EFI\>/{print\"$destinationDisk\"\$1}") || exit
	destinationEFI_UUID=$($sudo blkid $destinationEFI_FS -o value -s UUID) || exit

	echo "=> sourceEFI_FS = $sourceEFI_FS"
	echo "=> sourceEFI_UUID = $sourceEFI_UUID"
	echo "=> destinationEFI_FS = $destinationEFI_FS"
	echo "=> destinationEFI_UUID = $destinationEFI_UUID"
fi | tee -a "$logFile"

rsyncLogFile="$HOME/log/completeCopy_VG_To_SSD-$(date +%Y%m%d-%HH%M).log"
touch "$rsyncLogFile"
RSYNC_SKIP_COMPRESS_LIST=7z/aac/avi/bz2/deb/flv/gz/iso/jpeg/jpg/mkv/mov/m4a/mp2/mp3/mp4/mpeg/mpg/oga/ogg/ogm/ogv/webm/rpm/tbz/tgz/z/zip
RSYNC_EXCLUSION=$(printf -- "--exclude %s/ " /dev /sys /run /proc /mnt /media)
rsync="$(which rsync) -x -uth -P -z --skip-compress=$RSYNC_SKIP_COMPRESS_LIST $RSYNC_EXCLUSION --log-file=$rsyncLogFile"

cp2ext234="$rsync -ogpuv -lSH"
cp2ext234Partition="$rsync -ogpuv -lSH -x -r"
cp2FAT32="$rsync --modify-window=1"

destinationRootDir=/mnt/destinationVGDir

test -d $destinationRootDir/ || $sudo mkdir -v $destinationRootDir/
rootPartitionDevice=/dev/$destinationVG/$(echo $destinationLVList | tr " " "\n" | grep root)
if ! findmnt $destinationRootDir >/dev/null;then
	echo "=> Montage de la partition root dans $destinationRootDir/ ..."
	$sudo mount -v $rootPartitionDevice $destinationRootDir/ || { unmoutALLFSInDestination "$destinationRootDir";exit; }
fi | tee -a "$logFile"
echo

echo "=> Copie des fichiers de la partition / dans $destinationRootDir/ ..." | tee -a "$logFile"
time $sudo $cp2ext234 -r -x / $destinationRootDir/
sync
echo

test -d $destinationRootDir/usr || $sudo mkdir -v $destinationRootDir/usr
usrPartitionDevice=$(awk '/\s\/usr\s/{printf$1}' $destinationRootDir/etc/fstab)
if ! findmnt $destinationRootDir/usr >/dev/null;then
	echo "=> Montage de la partition $usrPartitionDevice  dans $destinationRootDir/usr ..."
	$sudo busybox mount -v $usrPartitionDevice $destinationRootDir/usr || { unmoutALLFSInDestination "$destinationRootDir";exit; }
fi | tee -a "$logFile"
echo

echo "=> Copie du repertoire lib de la partition /usr dans $destinationRootDir/usr ..." | tee -a "$logFile"
time $sudo $cp2ext234 -r -x /usr/lib $destinationRootDir/usr/
sync
echo

grep -q $destinationVG $destinationRootDir/etc/fstab 2>/dev/null || $sudo sed -i "s,$sourceVG,$destinationVG," $destinationRootDir/etc/fstab
if $efiMode;then
	grep -q $destinationEFI_UUID $destinationRootDir/etc/fstab 2>/dev/null || $sudo sed -i "s/$sourceEFI_UUID/$destinationEFI_UUID/" $destinationRootDir/etc/fstab
fi

echo "=> Creation des points de montage dans $destinationRootDir/ ..." | tee -a "$logFile"
awk '/^[^#]/{print substr($2,2)}' $destinationRootDir/etc/fstab | while read dir; do test -d $destinationRootDir/$dir || $sudo mkdir -p -v $destinationRootDir/$dir;done

echo "=> Montage de /proc a part ..." | tee -a "$logFile"
[ -d $destinationRootDir/proc ] || $sudo mkdir -v $destinationRootDir/proc
$sudo mount -v -t proc proc $destinationRootDir/proc

echo "=> Montage de /run a part ..." | tee -a "$logFile"
[ -d $destinationRootDir/run ] || $sudo mkdir -v $destinationRootDir/run
$sudo mount -v -t tmpfs tmpfs $destinationRootDir/run

echo "=> Binding des specialFS de /dev ..." | tee -a "$logFile"
for specialFS in dev dev/pts sys; do test -d $destinationRootDir/$specialFS/ || $sudo mkdir $destinationRootDir/$specialFS/; $sudo mount -v --bind /$specialFS $destinationRootDir/$specialFS ; done | tee -a "$logFile"
$efiMode && $sudo mkdir -p -v $destinationRootDir/sys/firmware/efi/efivars && $sudo mount -v --bind /sys/firmware/efi/efivars $destinationRootDir/sys/firmware/efi/efivars | tee -a "$logFile"
echo

echo "=> Montage via chroot de toutes les partitions de $destinationRootDir/etc/fstab ..." | tee -a "$logFile"
$sudo chroot $destinationRootDir/ $SHELL <<-EOF
	busybox mount -a 2>&1 >/dev/null | busybox awk '/No such file or directory/{print\$5}' | busybox xargs -r mkdir -pv
EOF
echo

sourceBootDevice=$(findmnt -n -c -o SOURCE /boot)
destinationBootDevice=$(findmnt -n -c -o SOURCE $destinationRootDir/boot)
sourceRootDeviceBaseName=$(findmnt -n -c -o SOURCE / | awk -F"[/ ]" '{printf$4}')
destinationRootDeviceBaseName=$(findmnt -n -c -o SOURCE $destinationRootDir | awk -F"[/ ]" '{printf$4}')
{
echo "=> sourceBootDevice = $sourceBootDevice"
echo "=> destinationBootDevice = $destinationBootDevice"
echo "=> sourceRootDeviceBaseName = <$sourceRootDeviceBaseName>"
echo "=> destinationRootDeviceBaseName = <$destinationRootDeviceBaseName>"
echo
} | tee -a "$logFile"

trap 'rc=127;set +x;echo "=> $scriptBaseName: CTRL+C Interruption trapped.">&2;unmoutALLFSInDestination "$destinationRootDir";exit $rc' INT

fsRegExp="\<(ext[234]|btrfs|f2fs|xfs|jfs|reiserfs|nilfs|hfs|vfat|fuseblk)\>"
echo "=> Liste des filesystem montes dans $destinationRootDir/" | tee -a "$logFile"
$df -PTh | awk "/$fsRegExp/" | egrep "$destinationRootDir"
echo

echo "=> Copie de tous les filesystem ..." | tee -a "$logFile"
sourceFilesystemsList=$($df -T | egrep -vw "/media|/mnt|/tmp" | awk "/$fsRegExp/"'{print$NF}' | sort -u)
sourceDirList=$sourceFilesystemsList
#sourceDirList=$(echo "$sourceDirList" | egrep -v "/datas|/home|/iso")
sourceDirList=$(echo "$sourceDirList" | paste -sd' ' | sed "s,/ \| /$,,g")
echo "=> sourceDirList= <$sourceDirList>"
test -z "$sourceDirList" && { unmoutALLFSInDestination "$destinationRootDir";exit; } | tee -a "$logFile"
for sourceDir in $sourceDirList
do
	destinationDir=${destinationRootDir}$sourceDir
	sourceFSType=$(mount | grep -v $destinationRootDir | grep "$sourceDir " | awk '{print$5}')
	echo "=> sourceDir = $sourceDir destinationDir = $destinationDir sourceFSType = $sourceFSType"

	case $sourceFSType in
		vfat) copyCommand="$cp2FAT32 -x";;
		ext2|ext3|ext4) copyCommand="$cp2ext234 -x";;
		*) copyCommand=echo;;
	esac

	echo
	mount | grep -q "$destinationDir\s" && time $sudo $copyCommand -r $sourceDir/ $destinationDir/
	echo
	sync
done | tee -a "$logFile"

#set +o pipefail
#dnsSERVER=$(host -v something.unknown | awk -F "[ #]" '/Received /{print$5}' | uniq | grep -q 127.0.0 && ( nmcli -f IP4.DNS,IP6.DNS dev list || nmcli -f IP4.DNS,IP6.DNS dev show ) 2>/dev/null | awk '/IP4.DNS/{printf$NF}')

set +o nounset
srcVG_UUID=$($sudo \vgs --noheadings -o uuid $sourceVG | awk '{printf$1}')
dstVG_UUID=$($sudo \vgs --noheadings -o uuid $destinationVG | awk '{printf$1}')
srcBootLV_UUID=$(sudo \lvs --noheadings -o uuid $sourceBootDevice | awk '{printf$1}')
dstBootLV_UUID=$(sudo \lvs --noheadings -o uuid $destinationBootDevice | awk '{printf$1}')
srcGrubBootLVMID=lvmid/$srcVG_UUID/$srcBootLV_UUID
dstGrubBootLVMID=lvmid/$dstVG_UUID/$dstBootLV_UUID

time $sudo chroot $destinationRootDir/ $SHELL <<-EOF
#	mv -v /etc/resolv.conf /etc/resolv.conf.back
#	echo nameserver $dnsSERVER > /etc/resolv.conf
	mount | grep " / " | grep -q rw || mount -v -o remount,rw /
	grep "use_lvmetad\s*=\s*1" /etc/lvm/lvm.conf
	grep -q "use_lvmetad\s*=\s*1" /etc/lvm/lvm.conf && sed -i "/^\s*use_lvmetad/s/use_lvmetad\s*=\s*1/use_lvmetad = 0/" /etc/lvm/lvm.conf
	echo
	grep "use_lvmetad\s*=\s*1" /etc/lvm/lvm.conf
	echo "=> Updating grub ..."
	update-grub
	grep -q $dstGrubBootLVMID /boot/grub/grub.cfg || sed -i "s,$srcGrubBootLVMID,$dstGrubBootLVMID,g" /boot/grub/grub.cfg
	grep -q $destinationRootDeviceBaseName /boot/grub/grub.cfg || sed -i "s,$sourceRootDeviceBaseName,$destinationRootDeviceBaseName,g" /boot/grub/grub.cfg
	[ -d /sys/firmware/efi ] && efiMode=true || efiMode=false
	echo "=> Installing grub ..."
	set -x
	$efiMode && grub-install --removable --efi-directory=$(mount | awk '/\/efi /{print$3}')
	$efiMode || grub-install $destinationDisk
	set +x
	if which lvmetad >/dev/null 2>&1;then
		grep -q "use_lvmetad\s*=\s*0" /etc/lvm/lvm.conf || sed -i "/^\s*use_lvmetad/s/use_lvmetad\s*=\s*0/use_lvmetad = 1/" /etc/lvm/lvm.conf
		grep "use_lvmetad\s*=\s*1" /etc/lvm/lvm.conf
	fi
	sync
EOF
set -o nounset
echo

unmoutALLFSInDestination "$destinationRootDir" | tee -a "$logFile"
trap - INT

$df -PTh | grep -q $destinationRootDir

echo "=> Restore grub in /dev/sda just in case ..." | tee -a "$logFile"
$efiMode && efiDirectory=$(mount | awk '/\/efi /{print$3}') && $sudo grub-install --efi-directory=$efiDirectory --removable || $sudo grub-install /dev/sda
sync
echo

echo "=> rsyncLogFile = <$rsyncLogFile>."
echo "=> logFile = <$logFile>."
