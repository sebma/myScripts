#!/usr/bin/env bash

trap 'rc=127;set +x;echo "=> $scriptBaseName: CTRL+C Interruption trapped.">&2;exit $rc' INT

scriptBaseName=${0##*/}
if [ $# != 1 ];then
	echo "=> Usage: $scriptBaseName mountPoint"
	exit 1
fi

mountPoint=$1
rc=0
time for p in $(seq 0 5 95);do
	echo "[$scriptBaseName] Running with $p% ..."
	time {
		sudo btrfs balance start -dusage=$p -musage=$p $mountPoint > btrfs-balance_$$.log 2>&1
		\grep -1 --color -i "error.*" btrfs-balance_$$.log && {
			rc=1
			break
			true
		} || {
			cat btrfs-balance_$$.log
		}
	}
	echo
done

echo
sudo btrfs filesystem usage -T $mountPoint
[ $rc = 0 ] && \rm btrfs-balance_$$.log

exit $rc

trap - INT
