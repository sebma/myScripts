#!/usr/bin/env bash

scriptName=$(basename $0)
declare -i virtualDiskNumber=-1
if [ $# = 0 ];then
    lastest=true
elif [ $# = 1 ];then
    if [ $1 = -h ];then
        echo "=> Usage : $scriptName virtualDiskNumber|[latest]|-l" >&2
        exit 1
    elif [ $1 = -l ];then
        listReadyPhysicalDisks=true
        id=$(omreport storage controller -fmt ssv | awk -F';' '/^[0-9];/{printf$1;exit}')
        omreport storage pdisk controller=$id | egrep '^(ID|Status|Capacity|Sector Size|Bus|Power|Media|State|Vendor|Product|Serial|Part.Number|^$)' | awk -v myPATTERN=Ready -v RS= '$0 ~ myPATTERN'
        exit $?
    else
        lastest=false
        virtualDiskNumber=$1
        if [ $virtualDiskNumber = 0 ];then
            echo "=> ERROR [$scriptName] : virtualDiskNumber must be an integer." >&2
            exit 2
        fi
    fi
else
    echo "=> Usage : $scriptName virtualDiskNumber|[latest]|-l" >&2
    exit 1
fi

declare -i last=-1
if which omreport >/dev/null;then
    id=$(omreport storage controller -fmt ssv | awk -F';' '/^[0-9];/{printf$1;exit}')
    raid=$(omreport storage vdisk controller=$id -fmt ssv | awk -F';' 'BEGIN{IGNORECASE=1}/virtual\s*disk\s*[0-9]+;/{value=$7}END{printf tolower(gensub("RAID-","r",1,value))}')
    pdisk=$(omreport storage pdisk controller=$id -fmt ssv | awk -F';' 'BEGIN{IGNORECASE=1}/Ready;/{value=$1;print value;exit}')
    if [ -z "$pdisk" ];then
        echo "=> There is no more physical disk in <Ready> state for this operation." >&2
        exit 1
    fi

    readpolicy=$(omreport storage vdisk controller=$id -fmt ssv | awk -F';' 'BEGIN{IGNORECASE=1}/virtual\s*disk\s*[0-9]+;/{value=$(NF-4)}END{printf tolower(value)}')
    writepolicy=$(omreport storage vdisk controller=$id -fmt ssv | awk -F';' 'BEGIN{IGNORECASE=1}/virtual\s*disk\s*[0-9]+;/{value=$(NF-3)}END{printf tolower(value)}')
    stripesize=$(omreport storage vdisk controller=$id -fmt ssv | awk -F';' 'BEGIN{IGNORECASE=1}/virtual\s*disk\s*[0-9]+;/{value=$(NF-1)}END{printf gensub(" ","",1,value)}')
    diskcachepolicy=$(omreport storage vdisk controller=$id -fmt ssv | awk -F';' 'BEGIN{IGNORECASE=1}/virtual\s*disk\s*[0-9]+;/{value=$NF}END{printf tolower(value)}')

    case $readpolicy in
        "read ahead") readpolicy=ra;;
        "adaptive read ahead") readpolicy=ara;;
        "no read ahead") readpolicy=nra;;
        "read cache") readpolicy=rc;;
        "no read cache") readpolicy=nrc;;
        *) echo "=> Unsupported read policy: <$readpolicy>." >&2;exit 2;;
    esac

    case $writepolicy in
        "write back") writepolicy=wb;;
        "write-through cache") writepolicy=wt;;
        "write cache") writepolicy=wc;;
        "force write back") writepolicy=fwb;;
        "no write cache") writepolicy=nwc;;
        *) echo "=> Unsupported write policy = <$writepolicy>." >&2;exit 3;;
    esac

    if $lastest;then
        last=$(omreport storage vdisk controller=$id -fmt ssv | awk -F';' 'BEGIN{IGNORECASE=1;last=1}/virtual\s*disk\s*[0-9]+;/{last+=1}END{printf last}')
        last+=1
        name=VirtualDisk$last
    else
        name=VirtualDisk$virtualDiskNumber
    fi
    echo "=> Creating $name for Physical Disk $pdisk ..."
    echo "=> omconfig storage controller action=createvdisk controller=$id raid=$raid size=max pdisk=$pdisk stripesize=$stripesize diskcachepolicy=$diskcachepolicy readpolicy=$readpolicy writepolicy=$writepolicy name=$name ..."
    time omconfig storage controller action=createvdisk controller=$id raid=$raid size=max pdisk=$pdisk stripesize=$stripesize diskcachepolicy=$diskcachepolicy readpolicy=$readpolicy writepolicy=$writepolicy name=$name
    retCode=$?
    echo "=> retCode = $retCode"
    echo "=> The new created Virtual Disk is :"
    omreport storage vdisk controller=$id -fmt ssv | grep "$name"
fi

exit $retCode
