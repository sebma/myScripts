#!/usr/bin/env bash

# grep -vw rootfs /proc/mounts | sudo tee /etc/mtab
#sdiff -sw $(tput cols) /etc/mtab <(grep -vw rootfs /proc/mounts)
