#!/usr/bin/env bash

df=$(which df)
time $df -T | sort | egrep -vw "/mnt|/media|tmpfs|efi|vfat|fuse|fuseblk|squashfs|devtmpfs|^Filesystem.* on" | awk 'BEGIN{printf "sudo du -cxsk / "}{printf $NF" "}' | sh -x | awk '/\<total\>/{print$1/1024^2" GiB"}'
