#!/usr/bin/env bash

set -o nounset

direction=LinuxVersWindows
logDir=/var/log/synchro/
logFile=$logDir/synchro_${direction}_$(date +%Y%m%d_%HH%MM%S).log

windowsDevice=$(findfs LABEL=Windows7)
echo "=> windowsDevice = $windowsDevice"
udisksctl mount -b $windowsDevice
set -o errexit
windowsPath=$(mount | awk '/media/{print$3}')
echo "=> windowsPath = $windowsPath"

papaWindowsHome=$windowsPath/Users/Michel/
papaWindowsDirs="Desktop Documents Downloads Music Videos"

for dir in $papaWindowsDirs
do
	rsync -av --log-file=$logFile $HOME/$dir $papaWindowsHome/
done
rsync -av --log-file=$logFile $HOME/Pictures/* $papaWindowsHome/Pictures/
 
sync
udisksctl unmount -b $windowsDevice

exit 0
