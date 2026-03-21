#!/usr/bin/env bash

diskModel=$(sudo smartctl -i $diskDevice | awk '/Model:/{print$NF}')
sector_size=$(sudo smartctl -i /dev/sda | awk '/Sector Sizes?:/{print$3}')
echo "=> sector_size = $sector_size"
time sudo badblocks -b $sector_size -s -v -o ${diskModel}_badblocks.log /dev/sda
while read sector
do
	sudo hdparm --repair-sector $sector
done < ${diskModel}_badblocks.log
