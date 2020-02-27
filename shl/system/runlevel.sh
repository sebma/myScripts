#!/bin/bash

busybox="$(type -p busybox)"
awk="$busybox awk"
if $awk 2>&1 | grep -wq "Usage: awk";then
	systemctl -t target | egrep '^(emergency|rescue|graphical|multi-user|recovery|friendly-recovery)' | $awk '{print$1}'
else
	systemctl -t target | egrep '^(emergency|rescue|graphical|multi-user|recovery|friendly-recovery)'
fi
