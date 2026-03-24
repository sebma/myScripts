#!/usr/bin/env bash

# A IMPLEMENTER
echo 1 | sudo tee /sys/class/block/sd?/device/rescan >/dev/null
echo Fix | sudo parted ---pretend-input-tty /dev/sda print free
sudo parted -s /dev/sda resizepart 2 100%
sudo pvresize /dev/sda2
