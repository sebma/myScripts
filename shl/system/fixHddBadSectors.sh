#!/usr/bin/env bash

#set -o nounset
#set -o errexit

if [ ! $# = 1 ]
then
	echo "=> Usage: $0 device" >&2
	exit 1
fi

if type sudo >/dev/null 2>&1 
then
	sudo=$(which sudo)
else
	sudo=""
fi

baddrive=$1
deviceName=${baddrive:5:3}

#maxSectors=$($sudo fdisk -l $baddrive | awk "/Disk .dev/"'{print$(NF-1)}')
#maxSectors=$($sudo hdparm -N $baddrive | awk -F " *|/" '/sectors/{print$5}')
#maxSectors=$(awk /$deviceName$/'{print$3*2}' /proc/partitions)
maxSectors=$(</sys/block/$deviceName/size)

test $badsect || badsect=$(($maxSectors*99/100)) # To debug
#test $badsect || badsect=1 # Takes up to 10 hours so test the whole drive surface
echo "=> badsect = $badsect"

badSectorsLog=~/badSectors_$(date +%Y%m%d_%Hh%Mm%Ss).log

mount | awk  "/$deviceName/"'{print$3}' | while read mountPoint; do umount -v $mountPoint ; done

touch $badSectorsLog
while true; do
	echo Testing from LBA $badsect
	set -x
	if $sudo smartctl -t select,${badsect}-max ${baddrive}
	then
		set +x
		echo "Waiting 30 seconds for selective test to begin ..."
		sleep 30
	else
		set +x
	fi

	echo "Waiting for selective test to finish ..."
	time while [ "$($sudo smartctl -l selective ${baddrive} | awk '/^ *1/{print $4}')" = "Self_test_in_progress" ]; do
		smartctl -l selective /dev/sda | awk -F " *|-|\\\(" '/Self_test_in_progress/{printf"\r%.3f%% remaining ...",$9/$4*100}'
		sleep 1
	done
	echo

	badsect=$($sudo smartctl -l xselftest $baddrive | awk '/# 1  Selective offline   Completed: read failure/ {print $10}')
	[ "$badsect" = "-" ] || [ "$badsect" = "" ] && break
	echo "=> badsect = <$badsect>"

	echo Attempting to fix sector $badsect on $baddrive
	$sudo hdparm --repair-sector ${badsect} --yes-i-know-what-i-am-doing $baddrive
	echo Continuning test
done | tee -a $badSectorsLog

echo "=> The log file is <$badSectorsLog>."
$sudo fdisk -l $baddrive | awk "/NTFS/"'{print$1}' | while read partition
do
	$sudo ntfsresize -i $partition >/dev/null || {
		$sudo ntfsfix -b $partition
		echo "=> Reboot to Windows TWICE !"
	}
done
