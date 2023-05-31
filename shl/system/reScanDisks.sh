#!/usr/bin/env bash

echo "=> Re-scanning SCSI hosts for new disks devices, just in case ..."
time echo "- - -" | sudo tee /sys/class/scsi_host/host*/scan /sys/class/block/sd?/device/rescan >/dev/null
