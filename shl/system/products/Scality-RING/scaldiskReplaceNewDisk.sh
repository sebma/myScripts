#!/usr/bin/env bash

disk=$(time scaldisk iods list | awk '/OOS_PERM/{print$1;exit}')
while [ -n "$disk" ];do
	scaldisk replace -d $disk || exit
	disk=$(time scaldisk iods list | awk '/OOS_PERM/{print$1;exit}')
done
