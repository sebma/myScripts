#!/usr/bin/env sh

fsck -N /dev/mapper/* 2>/dev/null | egrep -v "/control|^fsck\>" | sort | awk '/btrfs/{print"btrfsck -p "$NF}!/btrfs/{notFound+=1;if(notFound==1)printf"fsck -ps ";else printf$NF" ";}' | sh -x
