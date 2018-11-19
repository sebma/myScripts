#!/usr/bin/env sh

fsck -N /dev/mapper/* 2>/dev/null | egrep -v "/control|^fsck" | awk '/btrfs/{print"btrfsck -p "$NF}!/btrfs/{print$(NF-1)" -p "$NF}' | sh -x
