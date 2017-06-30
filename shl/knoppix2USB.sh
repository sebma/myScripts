#!/bin/sh

MyScriptsDir=$(dirname $0)
SrcLoaderSubDir=isolinux
DstLoaderSubDir=syslinux
#SrcLoaderSubDir=syslinux
#DstLoaderSubDir=extlinux

[ $# -ne 1 ] && {
  echo "Usage: <$0> <Filesystem Type>" 1>&2
	exit 1
}

FilesystemPartitionType=$1
while [ -z "$USBKeyPartitionDeviceName" ]
do
  read -p"Please enter your USB Key device name [instance: /dev/sdb3]: " USBKeyPartitionDeviceName
done

echo "=> USBKeyPartitionDeviceName=$USBKeyPartitionDeviceName"

[ ! -b "$USBKeyPartitionDeviceName" ] && echo -e "\aERROR $USBKeyPartitionDeviceName is not a valid block device" 1>&2 && exit 2


PartitionNumber=$(echo $USBKeyPartitionDeviceName | tr -d "[a-z\/]")
KnoppixUSBPartitionMountPoint=$(echo "${USBKeyPartitionDeviceName}" | sed "s/dev/media/")
USBKeyDeviceName=$(echo $USBKeyPartitionDeviceName | tr -d "[0-9]")
LastUSBKeyPartitionMountPoint=$(ls -1 $USBKeyDeviceName? | tail -1 | sed "s/dev/media/")
echo "=> PartitionNumber=$PartitionNumber"
echo "=> KnoppixUSBPartitionMountPoint=$KnoppixUSBPartitionMountPoint"
echo "=> USBKeyDeviceName=$USBKeyDeviceName"
echo "=> LastUSBKeyPartitionMountPoint=$LastUSBKeyPartitionMountPoint"
#exit 1
SYSLINUX=$(type -p syslinux)
EXTLINUX=$(type -p extlinux)
SYSLINUX_NEW=$LastUSBKeyPartitionMountPoint/usr/bin/syslinux

echo "Partionning your USB Key, please create one partition of at least 1GB at the first position"
#sudo parted $USBKeyDeviceName
sudo fdisk $USBKeyDeviceName

echo "Formatting the first partition to $FilesystemPartitionType"
set -x
case "$FilesystemPartitionType" in
  FAT16|fat16)
	echo "=> mkdosfs -v -F16 ${USBKeyPartitionDeviceName} ..."
	#mkdosfs -v -F16 "${USBKeyPartitionDeviceName}"
  ;;
  FAT32|fat32)
	echo "=> mkdosfs -v -F32 ${USBKeyPartitionDeviceName} ..."
	#mkdosfs -v -F32 "${USBKeyPartitionDeviceName}"
  ;;
  ext2|ext3|reiserfs)
	echo "=> mkfs.${FilesystemPartitionType} -v ${USBKeyPartitionDeviceName} ..."
	#mkfs.${FilesystemPartitionType} -v "${USBKeyPartitionDeviceName}"
  ;;
  *)
  echo "Error wrong filesystem type: $FilesystemPartitionType" 1>&2
  exit 3
  ;;
esac

echo "Setting the bootable flag on the first USB"
sudo parted -s $USBKeyDeviceName set $PartitionNumber boot on
fdisk -l $USBKeyDeviceName

read -p"Type ENTER"
echo "Installing syslinux on $KnoppixUSBPartitionMountPoint "
case "$FilesystemPartitionType" in
  FAT16|fat16|FAT32|fat32)

set -x
mount -r $LastUSBKeyPartitionMountPoint && [ -x "$SYSLINUX_NEW" ] && {
	SYSLINUX_CFG=boot/$DstLoaderSubDir/syslinux.cfg
	BOOT_MSG=boot/$DstLoaderSubDir/boot.msg

	echo "Mount the $KnoppixUSBPartitionMountPoint partition and copy the files onto it ..."
	mount $KnoppixUSBPartitionMountPoint
	time sudo cp -v -R /cdrom/* $KnoppixUSBPartitionMountPoint/
	sync
	rm -v $KnoppixUSBPartitionMountPoint/boot/$SrcLoaderSubDir/${SrcLoaderSubDir}.*
	mv -v $KnoppixUSBPartitionMountPoint/boot/$SrcLoaderSubDir $KnoppixUSBPartitionMountPoint/boot/$DstLoaderSubDir
	sudo $SYSLINUX_NEW -d /boot/$DstLoaderSubDir "${USBKeyPartitionDeviceName}" && umount $LastUSBKeyPartitionMountPoint
} || {
	SYSLINUX_CFG=syslinux.cfg
	BOOT_MSG=boot.msg
	$SYSLINUX "${USBKeyPartitionDeviceName}"

	echo "Mount the $KnoppixUSBPartitionMountPoint partition and copy the files onto it ..."
	mount $KnoppixUSBPartitionMountPoint
	sudo cp -v /cdrom/boot/$SrcLoaderSubDir/* $KnoppixUSBPartitionMountPoint
	rm -v $KnoppixUSBPartitionMountPoint/*.bin
	sudo cp -v /cdrom/* $KnoppixUSBPartitionMountPoint
	sudo cp -v -R /cdrom/docs $KnoppixUSBPartitionMountPoint
	mkdir -v $KnoppixUSBPartitionMountPoint/KNOPPIX
	sudo cp -v -R /cdrom/KNOPPIX/{images,modules} $KnoppixUSBPartitionMountPoint/KNOPPIX
	sudo cp -v /cdrom/KNOPPIX/*.* $KnoppixUSBPartitionMountPoint/KNOPPIX
	sudo cp -v /cdrom/KNOPPIX/k* $KnoppixUSBPartitionMountPoint/KNOPPIX
	sudo cp -v /cdrom/KNOPPIX/md5* $KnoppixUSBPartitionMountPoint/KNOPPIX
	sync
	time sudo cp /cdrom/KNOPPIX/KNOPPIX $KnoppixUSBPartitionMountPoint/KNOPPIX
}

  ;;
  ext2|ext3)
  	echo "=> COUCOU !!!!"
	SYSLINUX_CFG=boot/$DstLoaderSubDir/extlinux.conf
	BOOT_MSG=boot/$DstLoaderSubDir/boot.msg

	echo "Mount the $KnoppixUSBPartitionMountPoint partition and copy the files onto it ..."
	mount $KnoppixUSBPartitionMountPoint
	time sudo cp -a /cdrom/* $KnoppixUSBPartitionMountPoint/
	sudo rm -f -v $KnoppixUSBPartitionMountPoint/boot/$SrcLoaderSubDir/${SrcLoaderSubDir}.*
	sudo mv -v $KnoppixUSBPartitionMountPoint/boot/$SrcLoaderSubDir $KnoppixUSBPartitionMountPoint/boot/$DstLoaderSubDir
	time sync
	#umount $KnoppixUSBPartitionMountPoint && exit 1
	sudo cat ${MyScriptsDir}/mbr.bin > "${USBKeyDeviceName}"
	sudo parted -s $USBKeyDeviceName set $PartitionNumber boot on
	sudo $EXTLINUX /boot/$DstLoaderSubDir
  ;;
  *)
  echo "Error wrong filesystem type: $FilesystemPartitionType" 1>&2
  exit 3
  ;;
esac

sync
#Definition d'un timeout de N secondes
declare -i TimeOut=10

sudo touch $KnoppixUSBPartitionMountPoint/$SYSLINUX_CFG
sudo chown knoppix:knoppix $KnoppixUSBPartitionMountPoint/$SYSLINUX_CFG

sed -e 's/BOOT_IMAGE=\(.*\)/BOOT_IMAGE=\1 noeject noprompt dma noswap/' /cdrom/boot/$SrcLoaderSubDir/${SrcLoaderSubDir}.cfg | sed -e "s/^.*TIMEOUT .*$/TIMEOUT ${TimeOut}0/" | \
#sudo bash -c "sed -e 's/APPEND #*$/APPEND #######################################################################################################################################################################################################################################################################/' > $KnoppixUSBPartitionMountPoint/$SYSLINUX_CFG"
sed -e 's/APPEND #*$/APPEND #######################################################################################################################################################################################################################################################################/' > $KnoppixUSBPartitionMountPoint/$SYSLINUX_CFG

sudo chown knoppix:knoppix $KnoppixUSBPartitionMountPoint/$BOOT_MSG
#sudo bash -c "sed -e \"s/ [0-9]\+s./ ${TimeOut}s./\" /cdrom/boot/$SrcLoaderSubDir/boot.msg > $KnoppixUSBPartitionMountPoint/$BOOT_MSG"
sed -e "s/ [0-9]\+s./ ${TimeOut}s./" /cdrom/boot/$SrcLoaderSubDir/boot.msg > $KnoppixUSBPartitionMountPoint/$BOOT_MSG

#set +x
sync
umount $KnoppixUSBPartitionMountPoint
#knoppix-mkimage

exit $?

