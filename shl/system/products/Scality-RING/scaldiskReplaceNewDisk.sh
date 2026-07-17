#!/usr/bin/env bash

set -o nounset

disk=$(time scaldisk iods list | awk '/OOS_PERM/{print$1;exit}')
while [ -n "$disk" ];do
	scaldisk replace -d $disk || exit
	disk=$(time scaldisk iods list | awk '/OOS_PERM/{print$1;exit}')
done
