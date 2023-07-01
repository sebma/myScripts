#!/usr/bin/env bash

distribName=$(lsb_release -si)
currentKernelVersion=$(uname -r | cut -d. -f1,2 | tr -d .)
if [ $distribName = Ubuntu ] && [ $currentKernelVersion -lt 44 ];then
	sudo apt install -V linux-generic-lts-xenial linux-headers-generic-lts-xenial linux-image-extra-virtual-lts-xenial linux-image-generic-lts-xenial
fi
