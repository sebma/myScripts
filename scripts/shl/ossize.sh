#!/usr/bin/env bash

#sudo du -sk --exclude=/mnt --exclude=/media --exclude=/proc --exclude=/run/user --exclude=/var/cache/apt --exclude=/usr/local --exclude=/opt --exclude=/tmp --exclude=/var/tmp --exclude=/boot --exclude=/home --exclude=/vids --exclude=/iso --exclude=/datas / | awk '/[0-9]/{print$1/1024^2" GiB"}'
df -T | sort | egrep -vi "tmpfs|efi|vfat|fuse" | awk 'BEGIN{printf "sudo du -cxsk / "}/boot|opt|tmp|usr|var/{printf $NF" "}' | sh | awk '/\<total\>/{print$1/1024^2" GiB"}'
