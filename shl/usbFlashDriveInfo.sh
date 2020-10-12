#!/usr/bin/env sh

usbFlashDriveDevice=$1
sudo smartctl -i -d scsi -T permissive $usbFlashDriveDevice
sudo parted $usbFlashDriveDevice print
sudo gdisk -l $usbFlashDriveDevice
