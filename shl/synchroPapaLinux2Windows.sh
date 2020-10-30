#!/usr/bin/env bash

set -o nounset

echo "=> ID = $(id -u)"
echo "=> USER = $USER"

direction=LinuxVersWindows
logDir=/var/log/synchro/
logFile=$logDir/synchro_${direction}_$(date +%Y%m%d_%HH%MM%S).log

windowsDevice=$(/sbin/findfs LABEL=Windows7)
echo "=> windowsDevice = $windowsDevice"
udisksctl mount -b $windowsDevice
set -o errexit
windowsPath=$(mount | awk '/media/{print$3}')
echo "=> windowsPath = $windowsPath"

papaWindowsHome=$windowsPath/Users/Michel/
papaWindowsDirs="Desktop Documents Downloads Music Videos"

time for dir in $papaWindowsDirs
do
	rsync -avh --log-file=$logFile $HOME/$dir $papaWindowsHome/
done
time rsync -avh --log-file=$logFile $HOME/Pictures/* $papaWindowsHome/Pictures/
 
sync
udisksctl unmount -b $windowsDevice

exit 0
