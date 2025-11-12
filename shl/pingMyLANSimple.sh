#!/usr/bin/env bash

function pingMyLANSimple {
    local myOutgoingInterFace=$(ip route | awk '/default/{print$5}')
    local myLAN=$(ip -4 addr show dev $myOutgoingInterFace scope global up | awk -F " *|/" '/inet/{print$3}')
    local prefix=$(ip -4 addr show dev $myOutgoingInterFace scope global up | awk -F " *|/" '/inet/{print$4}')
    local lanPrefix=$(echo $myLAN | cut -d. -f1-3)
    local nbHost=$((2**(32-$prefix)-1))

    for i in $(seq $(($nbHost-1)));do
        ping $lanPrefix.$i -c1 -W1 &
    done | grep from | sort -t . -k 4n
}

pingMyLANSimple
