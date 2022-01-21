#!/usr/bin/env bash

if ! grep -v "^#" /etc/fstab | grep -q "tmpfs.*/tmp"; 
then
	tmpfsSize=15%
	echo "tmpfs /tmp tmpfs rw,nosuid,nodev,size=$tmpfsSize" | sudo tee -a /etc/fstab
fi
