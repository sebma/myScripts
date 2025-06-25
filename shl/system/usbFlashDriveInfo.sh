#!/usr/bin/env bash

scriptName=$(basename $0)
usbFlashDriveInfo() {
	test $# != 1 && echo "=> Usage: $scriptName usbFlashDriveDevice" >&2 && return 1
	usbFlashDriveDevice=$1
	sudo smartctl -i -d scsi -T permissive $usbFlashDriveDevice
	sudo parted $usbFlashDriveDevice print
	sudo gdisk -l $usbFlashDriveDevice
}

usbFlashDriveInfo $1
