#!/usr/bin/env bash

trap 'echo "=> Ignoring this step and continuing the script <$(basename $0)> ..." >&2' INT
(
for i in `dpkg -l | grep '^ii' | awk '{print $2}'`; do
	echo $i; sudo dpkg-reconfigure $i;
done
) 2>&1 | tee dpkg-reconfigure.log

trap - INT
set -x
sudo dpkg --configure -a
sync
