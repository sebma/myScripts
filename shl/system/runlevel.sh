#!/bin/bash

busybox="$(type -p busybox)"
head="$busybox head"
if $head --help 2>&1 | grep -wq "Usage: head";then
	systemctl -t target | egrep -o '^(emergency|rescue|graphical|multi-user|recovery|friendly-recovery).target' | $head -1
else
	systemctl -t target | egrep -o '^(emergency|rescue|graphical|multi-user|recovery|friendly-recovery).target' | head -1 || systemctl -t target | egrep -o -m1 '^(emergency|rescue|graphical|multi-user|recovery|friendly-recovery).target'
fi
