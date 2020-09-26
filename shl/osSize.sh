#!/usr/bin/env bash

df=$(which df)
$df -T | sort | egrep -vi "tmpfs|efi|vfat|fuse|squashfs" | awk 'BEGIN{printf "sudo du -cxsk / "}/boot|opt|tmp|usr|var/{printf $NF" "}' | sh | awk '/\<total\>/{print$1/1024^2" GiB"}'
