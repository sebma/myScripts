#!/usr/bin/env bash

distribName=$(lsb_release -si)
currentKernelVersion=$(uname -r | cut -d. -f1,2 | tr -d .)
if [ $distribName = Ubuntu ];then
	sudo apt install -V linux-generic linux-headers-generic linux-image-extra-virtual linux-image-generic
fi
