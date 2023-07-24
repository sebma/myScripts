#!/usr/bin/env bash

declare -i last=-1
if which omreport >/dev/null;then
    id=$(omreport storage controller -fmt ssv | awk -F';' '/^[0-9];/{printf$1;exit}')
    last=$(omreport storage vdisk controller=$id -fmt ssv | awk -F';' 'BEGIN{IGNORECASE=1;last=1}/virtual\s*disk\s*[0-9]+;/{last+=1}END{printf last}')
    last+=1
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

    name=VirtualDisk$last
    echo "=> Creating $name for Physical Disk $pdisk ..."
    echo "=> omconfig storage controller action=createvdisk controller=$id raid=$raid size=max pdisk=$pdisk stripesize=$stripesize diskcachepolicy=$diskcachepolicy readpolicy=$readpolicy writepolicy=$writepolicy name=$name ..."
    time omconfig storage controller action=createvdisk controller=$id raid=$raid size=max pdisk=$pdisk stripesize=$stripesize diskcachepolicy=$diskcachepolicy readpolicy=$readpolicy writepolicy=$writepolicy name=$name
    retCode=$?
    echo "=> retCode = $retCode"
    echo "=> The new created Virtual Disk is :"
    omreport storage vdisk controller=$id -fmt ssv | grep "$name"
fi
exit $retCode
