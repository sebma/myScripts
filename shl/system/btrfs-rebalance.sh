#!/usr/bin/env bash

if [ $# != 1 ];then
	echo "=> Usage: $0 mountPoint"
	exit 1
fi

mountPoint=$1
time for p in $(seq 0 5 95);do
	echo "$0: Running with $p%"
	time sudo btrfs balance start -dusage=$p -musage=$p $mountPoint
done
