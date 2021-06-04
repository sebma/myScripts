#!/usr/bin/env bash

if ! grep -v "^#" /etc/fstab | grep -q "tmpfs.*/tmp"; 
then
#	tmpfsSize=$(awk '/^MemTotal/{size=0.15*$2/1024;printf int(size)"M"}' /proc/meminfo)
	tmpfsSize=15%
	echo "tmpfs /tmp tmpfs rw,nosuid,nodev,size=$tmpfsSize" | sudo tee -a /etc/fstab
fi
