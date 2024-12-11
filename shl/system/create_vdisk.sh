#!/usr/bin/env bash

scriptName=$(basename $0)
declare -i virtualDiskNumber=-1
declare -i last=-1
declare listReadyPhysicalDisks=false

if [ $# = 0 ];then
	lastest=true # Choose the latest VirtualDisk by default.
elif [ $# = 1 ];then
	if [ $1 = -h ];then
		echo "=> Usage : $scriptName virtualDiskNumber|[latest]" >&2
		echo "=> Usage : $scriptName -l : List physical disks that are Ready." >&2
		exit 1
	elif [ $1 = -l ];then
		listReadyPhysicalDisks=true
	else
		lastest=false
		virtualDiskNumber=$1
		if [ $virtualDiskNumber = 0 ];then
			echo "=> ERROR [$scriptName] : virtualDiskNumber must be an integer." >&2
			exit 2
		fi
	fi
else
	echo "=> Usage : $scriptName virtualDiskNumber|[latest]" >&2
	echo "=> Usage : $scriptName -l : List physical disks that are Ready." >&2
	exit 1
fi

if which omreport >/dev/null;then
	controllerID=$(omreport storage controller -fmt ssv | awk -F';' '/^[0-9];/{printf$1;exit}')

	if $listReadyPhysicalDisks;then
		omreport storage pdisk controller=$controllerID | egrep '^(ID|Status|State|Power|Media|Failure Predicted|Capacity|Sector Size|Bus|Vendor|Product|Serial|Part.Number|^$)' | awk -v myPATTERN=Ready -v RS='' -v ORS='\n\n' '$0 ~ myPATTERN'
		pdisk=$(omreport storage pdisk controller=$controllerID -fmt ssv | awk -F';' 'BEGIN{IGNORECASE=1}/Ready;/{value=$1;print value;exit}')
		[ -z "$pdisk" ] && echo "=> There is no more physical disk in <Ready> state." >&2
		exit 3
	fi

	if omreport storage vdisk controller=$controllerID | grep -i "Virtual\s*Disk$virtualDiskNumber\>" -q;then
		echo "=> ERROR [$scriptName] : VirtualDisk$virtualDiskNumber is already in use :" >&2
		vdiskID=$(omreport storage vdisk controller=$controllerID -fmt ssv | awk -F ';' "/VirtualDisk$virtualDiskNumber/"'{print$1;exit}')
		omreport storage vdisk controller=$controllerID vdisk=$vdiskID
		exit 4
	fi

	pdisk=$(omreport storage pdisk controller=$controllerID -fmt ssv | awk -F';' 'BEGIN{IGNORECASE=1}/Ready;/{value=$1;print value;exit}')
	if [ -z "$pdisk" ];then
		echo "=> There is no more physical disk in <Ready> state for this operation." >&2
		exit 5
	fi

	echo "=> The first physical disk in <Ready> state selected is <$pdisk> :"
	omreport storage pdisk controller=$controllerID pdisk=$pdisk| egrep '^(ID|Status|Capacity|Sector Size|Bus|Power|Media|State|Vendor|Product|Serial|Part.Number|^$)'

	# Fetching the RAID and Policy values from the latest Virtual Disk
	latestVirtualDiskID=$(omreport storage vdisk controller=$controllerID -fmt ssv | awk -F';' 'BEGIN{IGNORECASE=1}/virtual\s*disk\s*[0-9]+/{value=$1}END{printf value}')

	raid=$(omreport storage vdisk controller=$controllerID vdisk=$latestVirtualDiskID | awk '/Layout/{value=$NF;printf tolower(gensub("RAID-","r",1,value))}')
	readpolicy=$(omreport storage vdisk controller=$controllerID vdisk=$latestVirtualDiskID | awk '/Read Policy/{value=$(NF-1)" "$NF;printf tolower(value)}')
	writepolicy=$(omreport storage vdisk controller=$controllerID vdisk=$latestVirtualDiskID | awk '/Write Policy/{value=$(NF-1)" "$NF;printf tolower(value)}')
	stripesize=$(omreport storage vdisk controller=$controllerID vdisk=$latestVirtualDiskID | awk '/Stripe Element Size/{value=$(NF-1)$NF;printf tolower(value)}')
	diskcachepolicy=$(omreport storage vdisk controller=$controllerID vdisk=$latestVirtualDiskID | awk '/Disk Cache Policy/{value=$NF}END{printf tolower(value)}')

	case $readpolicy in
		"read ahead") readpolicy=ra;;
		"adaptive read ahead") readpolicy=ara;;
		"no read ahead") readpolicy=nra;;
		"read cache") readpolicy=rc;;
		"no read cache") readpolicy=nrc;;
		*) echo "=> Unsupported read policy: <$readpolicy>." >&2;exit 6;;
	esac

	case $writepolicy in
		"write back") writepolicy=wb;;
		"write-through cache") writepolicy=wt;;
		"write cache") writepolicy=wc;;
		"force write back") writepolicy=fwb;;
		"no write cache") writepolicy=nwc;;
		*) echo "=> Unsupported write policy = <$writepolicy>." >&2;exit 7;;
	esac

	if $lastest;then
		last=$(omreport storage vdisk controller=$controllerID -fmt ssv | awk -F';' 'BEGIN{IGNORECASE=1;last=1}/virtual\s*disk\s*[0-9]+;/{last+=1}END{printf last}')
		last+=1
		virtualDiskNumber=$last
	fi
	name=VirtualDisk$virtualDiskNumber

	echo '=> Checking if there is "Preserved Cache" on the controller' "$controllerID ..."
	if ! omreport storage controller controller=$controllerID | grep Preserved.Cache.*Not.Applicable -q;then
		echo "=> ERROR : There is Preserved Cache on the controller $controllerID." >&2
		echo "=> You need to flush the Preserved Cache of the controller $controllerID." >&2
		echo "=> You can flush the Preserved Cache of the controller $controllerID with this command :" >&2
		echo "=> omconfig storage controller action=discardpreservedcache controller=$controllerID force=disabled"
		exit 8
	fi
	echo

	echo "=> Creating $name for Physical Disk $pdisk ..."
	echo "=> omconfig storage controller action=createvdisk controller=$controllerID raid=$raid size=max pdisk=$pdisk stripesize=$stripesize diskcachepolicy=$diskcachepolicy readpolicy=$readpolicy writepolicy=$writepolicy name=$name ..."
	echo
	time omconfig storage controller action=createvdisk controller=$controllerID raid=$raid size=max pdisk=$pdisk stripesize=$stripesize diskcachepolicy=$diskcachepolicy readpolicy=$readpolicy writepolicy=$writepolicy name=$name
	retCode=$?
	echo "=> retCode = $retCode"

	if [ $retCode = 0 ];then
		echo "=> The new created Virtual Disk is :"
		vdiskID=$(omreport storage vdisk controller=$controllerID -fmt ssv | awk -F ';' "/VirtualDisk$virtualDiskNumber/"'{print$1;exit}')
		omreport storage vdisk controller=$controllerID vdisk=$vdiskID
	fi
else
	echo "=> ERROR [$scriptName] : DELL OpenManage omreport is not installed." >&2
	exit 2
fi

exit $retCode
