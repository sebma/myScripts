#!/usr/bin/env bash

set -o nounset

direction=WindowsVersLinux
logDir=/var/log/synchro/
logFile=$logDir/synchro_${direction}_$(date +%Y%m%d_%HH%MM%S).log

ID=$(id -u)
[ $ID = 0 ] && USER=root && HOME=/home/michel
(
ID=$(id -u)
echo "=> ID = $ID"
echo "=> USER = $USER"
windowsDevice=$(/sbin/findfs LABEL=Windows7)
echo "=> windowsDevice = $windowsDevice"

windowsPath=$(mount | awk /$(basename $windowsDevice)/'{print$3}')
if [ -n "$windowsPath" ]
then
	echo "=> $windowsDevice is already mounted in $windowsPath"
else

	if [ $ID = 0 ]
	then
		mount -v -o uid=michel $windowsDevice /mnt/michel
	else
		udisksctl mount -b $windowsDevice || ( echo "=> ERROR : Could not mount the windows data partition <$windowsDevice>." >&2 ; exit )
	fi
fi

set -o errexit
windowsPath=$(mount | awk /$(basename $windowsDevice)/'{print$3}')
echo "=> windowsPath = $windowsPath"

papaWindowsHome=$windowsPath/Users/Michel/
papaWindowsDirs="Desktop Documents Downloads Music Videos"

if [ $ID = 0 ]
then
	time for dir in $papaWindowsDirs
	do
		sudo su - michel -c "rsync -avh --log-file=$logFile $papaWindowsHome/$dir $HOME/"
	done
	sudo su - michel -c "time rsync -avh --log-file=$logFile $papaWindowsHome/Pictures/* $HOME/Pictures/"
else
	time for dir in $papaWindowsDirs
	do
		rsync -avh --log-file=$logFile $papaWindowsHome/$dir $HOME/
	done
	time rsync -avh --log-file=$logFile $papaWindowsHome/Pictures/* $HOME/Pictures/
fi
 
sync
[ $ID = 0 ] && umount -v $windowsDevice || udisksctl unmount -b $windowsDevice
) 2>&1 | tee -a ~michel/TESTS.log

exit 0
