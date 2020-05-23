#!/usr/bin/env bash

trap 'rc=127;set +x;echo "=> $scriptBaseName: CTRL+C Interruption trapped.">&2;exit $rc' INT

scriptBaseName=${0##*/}
if [ $# != 1 ];then
	echo "=> Usage: $scriptBaseName mountPoint"
	exit 1
fi

mountPoint=$1
time for p in $(seq 0 5 95);do
	echo "[$scriptBaseName] Running with $p% ..."
	time sudo btrfs balance start -dusage=$p -musage=$p $mountPoint
	echo
done
sudo btrfs filesystem usage -T $mountPoint

trap - INT
