#!/usr/bin/env bash

if ! grep -q tmpfs.*/tmp /etc/fstab;
then
	size=$(awk '/^MemTotal/{size=0.2*$2/1024;printf int(size)"M"}' /proc/meminfo)
	echo "tmpfs /tmp tmpfs rw,nosuid,nodev,size=$size" | sudo tee -a /etc/fstab
fi
