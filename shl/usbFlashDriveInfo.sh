#!/usr/bin/env sh

scriptName=$(basename $0)
usbFlashDriveInfo() {
	usbFlashDriveDevice=$1
	test $# != 1 && echo "=> Usage: $scriptName usbFlashDriveDevice" >&2 && return 1
	sudo smartctl -i -d scsi -T permissive $usbFlashDriveDevice
	sudo parted $usbFlashDriveDevice print
	sudo gdisk -l $usbFlashDriveDevice
}

usbFlashDriveInfo $1
