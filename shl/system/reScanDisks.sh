#!/usr/bin/env bash

echo "=> Re-scanning existing disks for changes (such as size for virtual disks), just in case ..."
time echo "- - -" | sudo tee /sys/class/block/sd?/device/rescan >/dev/null
