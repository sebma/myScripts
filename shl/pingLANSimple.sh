#!/usr/bin/env bash

function pingLANSimple {
	local lanCIDR=$1
	local prefix=${lanCIDR#*/}
	local lanPrefix=$(echo $lanCIDR | cut -d. -f1-3)
	local nbHost=$((2**(32-$prefix)-1))

	for i in $(seq $(($nbHost-1)));do
		ping $lanPrefix.$i -c1 -W1 &
	done | grep from | sort -t . -k 4n
}

pingLANSimple $1
