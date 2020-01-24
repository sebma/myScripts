#!/usr/bin/env bash
(
for i in `dpkg -l | grep '^ii' | awk '{print $2}'`; do
	echo $i; sudo dpkg-reconfigure $i;
done
) 2>&1 | tee dpkg-reconfigure.log
