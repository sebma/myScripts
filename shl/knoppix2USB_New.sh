#!/bin/sh

[ $# -ne 1 ] && {
  echo "Usage: <$0> <Filesystem Type>" 1>&2
	exit 1
}

FilesystemPartitionType=$1
while [ -z "$USBKeyDeviceName" ]
do
  read -p"Please enter your USB Key device name: " USBKeyDeviceName
done


[ ! -b "$USBKeyDeviceName" ] && echo -e "\aERROR $USBKeyDeviceName is not a valid block device" 1>&2 && exit 2

echo "USBKeyDeviceName=$USBKeyDeviceName"
KnoppixUSBPartitionName=$(echo "${USBKeyDeviceName}1" | sed "s/dev/media/")
SecondPartitionName=$(echo $KnoppixUSBPartitionName | sed "s/sd\(.\)./sd\12/")

SYSLINUX=$(type -p syslinux)
SYSLINUX_NEW=$SecondPartitionName/usr/bin/syslinux

echo "Partionning your USB Key, please create one partition of at least 1GB at the first position"
#sudo parted $USBKeyDeviceName
sudo fdisk $USBKeyDeviceName

echo "Formatting the first partition to $FilesystemPartitionType"
set -x
case "$FilesystemPartitionType" in
  FAT16|fat16)
	echo "=> mkdosfs -v -F16 ${USBKeyDeviceName}1 ..."
	#mkdosfs -v -F16 "${USBKeyDeviceName}1"
	mkdosfs -v -F16 "${USBKeyDeviceName}1"
  ;;
  FAT32|fat32)
	echo "=> mkdosfs -v -F32 ${USBKeyDeviceName}1 ..."
	#mkdosfs -v -F32 "${USBKeyDeviceName}1"
	mkdosfs -v -F32 "${USBKeyDeviceName}1"
  ;;
  ext2|ext3|reiserfs)
	echo "=> mksfs.${FilesystemPartitionType} -v ${USBKeyDeviceName}1 ..."
	#mksfs.${FilesystemPartitionType} -v "${USBKeyDeviceName}1"
	mksfs.${FilesystemPartitionType} -v "${USBKeyDeviceName}1"
  ;;
  *)
  echo "Error wrong filesystem type: $FilesystemPartitionType" 1>&2
  exit 3
  ;;
esac

echo "Setting the bootable flag on the first USB"
sudo parted -s $USBKeyDeviceName set 1 boot on
fdisk -l $USBKeyDeviceName

read -p"Type ENTER"
echo "Installing syslinux on $KnoppixUSBPartitionName "
set -x
mount -r $SecondPartitionName && [ -x "$SYSLINUX_NEW" ] && {
	SYSLINUX_CFG=./boot/syslinux/syslinux.cfg
	BOOT_MSG=./boot/syslinux/boot.msg

	echo "Mount the $KnoppixUSBPartitionName partition and copy the files onto it ..."
	mount $KnoppixUSBPartitionName
	time sudo cp -v -R /cdrom/* $KnoppixUSBPartitionName/
	sync
	mv -v $KnoppixUSBPartitionName/boot/isolinux $KnoppixUSBPartitionName/boot/syslinux
	rm -v $KnoppixUSBPartitionName/boot/syslinux/isolinux.*
	sudo $SYSLINUX_NEW -d /boot/syslinux "${USBKeyDeviceName}1" && umount $SecondPartitionName
} || {
	umount $SecondPartitionName

	SYSLINUX_CFG=syslinux.cfg
	BOOT_MSG=boot.msg
	$SYSLINUX "${USBKeyDeviceName}1"

	echo "Mount the $KnoppixUSBPartitionName partition and copy the files onto it ..."
	mount $KnoppixUSBPartitionName
	sudo cp -v /cdrom/boot/isolinux/* $KnoppixUSBPartitionName
	rm -v $KnoppixUSBPartitionName/isolinux.bin
	mv -v -f $KnoppixUSBPartitionName/isolinux.cfg $KnoppixUSBPartitionName/syslinux.cfg
	sudo cp -v /cdrom/* $KnoppixUSBPartitionName
	sudo cp -v -R /cdrom/docs $KnoppixUSBPartitionName
	mkdir -v $KnoppixUSBPartitionName/KNOPPIX
	sudo cp -v -R /cdrom/KNOPPIX/{images,modules} $KnoppixUSBPartitionName/KNOPPIX
	sudo cp -v /cdrom/KNOPPIX/*.* $KnoppixUSBPartitionName/KNOPPIX
	sudo cp -v /cdrom/KNOPPIX/k* $KnoppixUSBPartitionName/KNOPPIX
	sudo cp -v /cdrom/KNOPPIX/md5* $KnoppixUSBPartitionName/KNOPPIX
	sync
	time sudo cp /cdrom/KNOPPIX/KNOPPIX $KnoppixUSBPartitionName/KNOPPIX
}

sync
#Definition d'un timeout de N secondes
declare -i TimeOut=10
#sed -e 's/BOOT_IMAGE=\(.*\) /BOOT_IMAGE=$1 noeject noprompt dma noswap/' /cdrom/boot/isolinux/isolinux.cfg | sed -e 's/^.*TIMEOUT .*$/TIMEOUT 100/' | \
sed -e 's/BOOT_IMAGE=\(.*\)/BOOT_IMAGE=\1 noeject noprompt dma noswap/' /cdrom/boot/isolinux/isolinux.cfg | sed -e "s/^.*TIMEOUT .*$/TIMEOUT ${TimeOut}0/" | \
sed -e 's/APPEND #*$/APPEND #######################################################################################################################################################################################################################################################################/' \
 > $KnoppixUSBPartitionName/$SYSLINUX_CFG
sed -e "s/ [0-9]\+s./ ${TimeOut}s./" /cdrom/boot/isolinux/boot.msg > $KnoppixUSBPartitionName/$BOOT_MSG
#set +x
sync
umount $KnoppixUSBPartitionName
#knoppix-mkimage

exit $?

