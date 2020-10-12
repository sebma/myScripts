#!/usr/bin/env bash

#set -o errexit
set -o nounset
type smartctl >/dev/null || exit
sudo=$(which sudo 2>/dev/null)
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

smartctlDiskInfo="$($sudo smartctl -i $diskDevice)"
which hdparm >/dev/null 2>&1 && hdparmDiskInfo="$($sudo hdparm -i $diskDevice)" && hdparmDiskMoreInfo="$($sudo hdparm -I $diskDevice)"
diskModel="$(echo "$smartctlDiskInfo" |  awk '/Model:/{gsub("/","_");for(i=4;i<NF;++i)printf $i"_";print$i}')"
test -z $diskModel && diskModel="$(echo "$smartctlDiskInfo" |  awk '/Model:/{gsub("/","_");for(i=3;i<NF;++i)printf $i"_";print$i}')"
test -z $diskModel && which hdparm >/dev/null 2>&1 && diskModel="$(echo "$hdparmDiskInfo" | awk -F'[=,]' '/Model=/{print$2}')"
test -z $diskModel && echo "=> ERROR : Could not infer diskModel." 2>/dev/null && exit 2

diskFamily="$(echo "$smartctlDiskInfo" |  awk '/Family:/{gsub("/","_");for(i=3;i<NF;++i)printf $i"_";print$i}')"
test -z $diskFamily && diskFamily="$(echo "$smartctlDiskInfo" |  awk '/Model:/{gsub("/","_");for(i=3;i<NF;++i)printf $i"_";print$i}')"
diskFamily="$(echo $diskFamily | sed -E "s/[.]+$|\"//g")"

logDir=$HOME/log
mkdir -p $logDir
logFile=$logDir/smartctl__${diskFamily}__${diskModel}-$(date +%Y%m%d-%HH%M).log
echo
trap 'rc=$?;set +x;echo "=> CTRL+C Interruption trapped.">&2;echo;echo "=> logFile = $logFile";exit $rc' INT

blink=$(tput blink)
bold=$(tput bold)
normal=$(tput sgr0)
red=$(tput setaf 1)
blue=$(tput setaf 4)
{
	echo "=> Disk general info for $diskFamily model $diskModel on $diskDevice :"
	echo
	deviceType=$(test $(</sys/block/${diskDevice/*\//}/queue/rotational) = 0 && echo SSD || echo HDD)
	printf $blue$bold
	echo "=> $diskFamily model $diskModel is a $deviceType drive."
	echo $normal
	echo "$smartctlDiskInfo"
	echo
	test $deviceType = SSD && $sudo smartctl -l ssd $diskDevice && echo
	echo "=> Enabling SMART on $diskFamily model $diskModel on $diskDevice ..."
	echo
	$sudo smartctl --smart=on --offlineauto=on --saveauto=on $diskDevice >/dev/null

	if ! sudo smartctl -l error $diskDevice | grep -q No.Errors;then
		echo "=> Error counter log pages for reads, write and verifies on $diskFamily model $diskModel on $diskDevice ..."
		echo
		printf $red$bold
		$sudo smartctl -l error $diskDevice | \grep -A1 -m1 Command/Feature_Name
		$sudo smartctl -l error $diskDevice | grep Error:
		echo $normal
	fi
	if ! sudo smartctl -l xerror $diskDevice | grep -q No.Errors;then
		echo "=> Extended Comprehensive SMART error log on $diskFamily model $diskModel on $diskDevice ..."
		echo
		printf $red$bold
		$sudo smartctl -l xerror $diskDevice | \grep -A1 -m1 Command/Feature_Name
		$sudo smartctl -l xerror $diskDevice | grep Error:
		echo $normal
	fi

	which hdparm >/dev/null 2>&1 && echo "=> hdparm info for $diskFamily model $diskModel on $diskDevice :" && echo "$hdparmDiskMoreInfo"

#	echo "=> Printing all SMART and non-SMART information about the $diskFamily model $diskModel on $diskDevice :"
#	echo
#	$sudo smartctl $allInformation $diskDevice
#	echo "=> Running a short self test for one minute for $diskFamily model $diskModel on $diskDevice :"
#	echo
#	$sudo smartctl -t short $diskDevice && sleep 60
	echo "=> Disk Self-Test results for $diskFamily model $diskModel on $diskDevice :"
	echo
	$sudo smartctl -H -l selftest $diskDevice
	echo "=> Disk Errors for $diskFamily model $diskModel on $diskDevice for the SMART Self-Test Log :"
	echo
	printf $red$bold
	$sudo smartctl -q errorsonly -H -l selftest $diskDevice
	printf $normal
	echo "=> Disk Errors for $diskFamily model $diskModel on $diskDevice for the SMART Error Log :"
	echo
	printf $red$bold
	$sudo smartctl -q errorsonly -H -l error $diskDevice
	printf $normal 
	echo "=> SMART Attributes Data for $diskFamily model $diskModel on $diskDevice :"
	echo
	$sudo smartctl -A $diskDevice
	echo "=> SMART Reallocated_Sector_Ct, Current_Pending_Sector, Offline_Uncorrectable specific Attributes for $diskFamily model $diskModel on $diskDevice :"
	echo
	$sudo smartctl -A $diskDevice | egrep -v " 0$" | egrep "(Reallocated_Sector_Ct|Current_Pending_Sector|Offline_Uncorrectable)" | egrep --color=always " [0-9]+$" && echo
	echo "=> SMART Pre-fail non-zero values :"
	echo
	$sudo smartctl -A $diskDevice | egrep -v " 0$" | egrep "Pre-fail" | egrep --color=always " [0-9]+$" && echo
	echo "=> journalctl \"smartd\" errors :"
	echo
	sudo journalctl -e -q -p 3 | grep --color=always smartd.*$diskDevice.*
	echo
	echo "=> Disk temperature using smartctl :"
	echo
	$sudo smartctl -A $diskDevice | egrep "VALUE|Temperature_Cel"
	echo
	$sudo smartctl -l scttempsts $diskDevice | tail -n +5
	printf "=> Disk temperature using hddtemp :"
	sudo hddtemp $diskDevice 2>&1 | cut -d: -f3 | tr -s ' ' | grep --color=always .
} 2>&1 | tee $logFile

echo
echo "=> logFile = $logFile"

trap - INT
