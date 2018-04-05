#!/usr/bin/env bash

#set -o errexit
set -o nounset
type smartctl >/dev/null || exit
type sudo >/dev/null 2>&1 && sudo=$(which sudo) || sudo=""
diskDevice=""
os=$(uname -s)

if [ $# = 0 ] 
then
	[ $os = Linux  ] && diskDevice=sda
	[ $os = Darwin ] && diskDevice=disk0
else
	[ "$1" = "-h" ] && {
		echo "=> Usage: $0 [disk device name]" >&2
		exit 1
	} || diskDevice=$1
fi

if ! echo $diskDevice | grep -q /dev/; then 
	diskDevice=/dev/$diskDevice
fi

smartctlMajorVersion=$(smartctl -V | awk '/release/{print$3}' | cut -d. -f1)
smartctlVersion=$(smartctl -V | awk '/release/{print$3}')

if perl -e "exit(!($smartctlVersion >= 5.41))" 
then
	allInformation=-x
else
	allInformation=-a
fi

diskModel=$($sudo smartctl -i $diskDevice | awk '/Model:/{print$NF}')
test -z $diskModel && exit
diskFamily="$($sudo smartctl -i $diskDevice |  awk '/Family:/{gsub("/","_");for(i=3;i<NF;++i)printf $i"_";print$i}')"
logDir=$HOME/log
logFile=$logDir/$(echo smartctl_$diskFamily $diskModel | sed "s/[ .]/_/g").log
mkdir -p $logDir

{
	echo "=> Enabling SMART on disk $diskFamily $diskModel on $diskDevice :"
	$sudo smartctl --smart=on --offlineauto=on --saveauto=on $diskDevice
	which hddparm >/dev/null 2>&1 && echo "=> hdparm info for disk $diskFamily $diskModel on $diskDevice :" && $sudo hdparm -I $diskDevice
	echo "=> Printing all SMART and non-SMART information about the disk $diskFamily $diskModel on $diskDevice :"
	$sudo smartctl $allInformation $diskDevice
	#echo "=> Running a short self test for one minute for disk $diskFamily $diskModel on $diskDevice :"
	#$sudo smartctl -t short $diskDevice && sleep 60
	echo "=> Disk tests results for disk $diskFamily $diskModel on $diskDevice :"
	$sudo smartctl -H -l selftest $diskDevice
	echo "=> Disk Errors for disk $diskFamily $diskModel on $diskDevice :"
	$sudo smartctl -q errorsonly -H -l selftest $diskDevice
	echo "=> Disk temperature using smartctl :"
	$sudo smartctl $allInformation $diskDevice | grep Temperature | head -5
	which hddtemp >/dev/null 2>&1 && echo "=> Disk temperature using hddtemp :" && $sudo hddtemp $diskDevice
} 2>&1 | tee $logFile

echo
echo "=> logFile = $logFile"

