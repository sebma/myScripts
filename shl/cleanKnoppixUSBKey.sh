#!/usr/bin/env bash

while [ -z "$USBKeyDeviceName" ]
do
  read -p"Please enter your USB Key device name: " USBKeyDeviceName
done


[ ! -b "$USBKeyDeviceName" ] && echo -e "\aERROR $USBKeyDeviceName is not a valid block device" 1>&2 && exit 1

echo "USBKeyDeviceName=$USBKeyDeviceName"
KnoppixUSBPartitionName=$(echo "${USBKeyDeviceName}1" | sed "s/dev/media/")

fdisk -l $USBKeyDeviceName

set +x
echo "Mount the $KnoppixUSBPartitionName partition and clean the files onto it ..."
mount $KnoppixUSBPartitionName
rm -vf $KnoppixUSBPartitionName/*
rm -vf -R $KnoppixUSBPartitionName/docs
rm -vf -R $KnoppixUSBPartitionName/KNOPPIX/{images,modules}
rm -vf $KnoppixUSBPartitionName/KNOPPIX/*.*
rm -vf $KnoppixUSBPartitionName/KNOPPIX/k*
rm -vf $KnoppixUSBPartitionName/KNOPPIX/m*
set -x
sync
umount $KnoppixUSBPartitionName

exit $?

