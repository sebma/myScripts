#!/usr/bin/env sh

#fsck -N /dev/mapper/* 2>/dev/null | egrep -v "/control|^fsck\>" | sort | awk '!/btrfs/{notFound+=1;if(notFound==1)printf"fsck -ps ";else printf$NF" ";}END{print""}'
fsck -N /dev/mapper/* 2>/dev/null | egrep -v "/control|^fsck\>" | sort | awk '!/btrfs/{print"fsck -p "$NF}' | while read line;
do
  FS=$(echo $line | awk '{print$NF}')
  mount | \grep -wq $FS || echo $line
done | sh -x
