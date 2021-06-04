#!/usr/bin/env bash

if ! grep -v "^#" /etc/fstab | grep -q "tmpfs.*/tmp"; 
then
	size=$(awk '/^MemTotal/{size=0.2*$2/1024;printf int(size)"M"}' /proc/meminfo)
	echo "tmpfs /tmp tmpfs rw,nosuid,nodev,size=$size" | sudo tee -a /etc/fstab
fi
