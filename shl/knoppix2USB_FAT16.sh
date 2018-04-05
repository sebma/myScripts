#!/bin/sh

#echo "Setting the root password ..."
#sudo passwd

while [ -z "$USBKeyDeviceName" ]
do
  read -p"Please enter your USB Key device name: " USBKeyDeviceName
done


[ ! -b "$USBKeyDeviceName" ] && echo -e "\aERROR $USBKeyDeviceName is not a valid block device" 1>&2 && exit 1

echo "USBKeyDeviceName=$USBKeyDeviceName"
KnoppixUSBPartitionName=$(echo "${USBKeyDeviceName}1" | sed "s/dev/media/")

echo "Partionning your USB Key, please create at least 1GB FAT16 partition at the first position"
sudo parted $USBKeyDeviceName

echo "Formatting the first partition to FAT16"
set -x
#mkdosfs -v -F16 "${USBKeyDeviceName}1"

echo "Setting the bootable flag on the first USB"
sudo parted -s $USBKeyDeviceName set 1 boot on
fdisk -l $USBKeyDeviceName

read -p"Type ENTER"
echo "Installing syslinux on $KnoppixUSBPartitionName "
syslinux "${USBKeyDeviceName}1"

set +x
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
#sudo time -p cp /cdrom/KNOPPIX/KNOPPIX $KnoppixUSBPartitionName/KNOPPIX
set -x
sync
umount $KnoppixUSBPartitionName
knoppix-mkimage

exit $?

