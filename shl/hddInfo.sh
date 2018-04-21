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
	echo "=> Disk general info for $diskFamily model $diskModel on $diskDevice :"
	echo
	$sudo smartctl -i $diskDevice
	echo "=> Enabling SMART on disk $diskFamily model $diskModel on $diskDevice ..."
	echo
	$sudo smartctl --smart=on --offlineauto=on --saveauto=on $diskDevice >/dev/null
	which hddparm >/dev/null 2>&1 && echo "=> hdparm info for disk $diskFamily model $diskModel on $diskDevice :" && $sudo hdparm -I $diskDevice
#	echo "=> Printing all SMART and non-SMART information about the disk $diskFamily model $diskModel on $diskDevice :"
#	echo
#	$sudo smartctl $allInformation $diskDevice
#	echo "=> Running a short self test for one minute for disk $diskFamily model $diskModel on $diskDevice :"
#	echo
#	$sudo smartctl -t short $diskDevice && sleep 60
	echo "=> Disk Self-Test results for $diskFamily model $diskModel on $diskDevice :"
	echo
	$sudo smartctl -H -l selftest $diskDevice
	echo "=> Disk Errors for disk $diskFamily model $diskModel on $diskDevice for the SMART Self-Test Log :"
	echo
	$sudo smartctl -q errorsonly -H -l selftest $diskDevice
	echo "=> Disk Errors for disk $diskFamily model $diskModel on $diskDevice for the SMART Error Log :"
	echo
	$sudo smartctl -q errorsonly -H -l error $diskDevice
	echo "=> SMART Attributes Data for $diskFamily model $diskModel on $diskDevice :"
	echo
	$sudo smartctl -A $diskDevice
	echo "=> Disk temperature using smartctl :"
	echo
	$sudo smartctl $allInformation $diskDevice | grep Temperature | head -5
	echo
	which hddtemp >/dev/null 2>&1 && echo "=> Disk temperature using hddtemp :" && echo && $sudo hddtemp $diskDevice
} 2>&1 | tee $logFile

echo
echo "=> logFile = $logFile"

