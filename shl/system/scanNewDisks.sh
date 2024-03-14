#!/usr/bin/env bash

echo "=> Re-scanning SCSI hosts for new disks, just in case ..."
time echo "- - -" | sudo tee /sys/class/scsi_host/host*/scan >/dev/null
