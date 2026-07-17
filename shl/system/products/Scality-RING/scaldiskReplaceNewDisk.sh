#!/usr/bin/env bash

disk=$(time scaldisk iods list | grep -vw OK)
while [ -n "$disk" ]
do
	disk=$(time scaldisk iods list | awk '/OOS_PERM/{print$1;exit}')
	scaldisk replace -d $disk
done
