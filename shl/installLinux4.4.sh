#!/usr/bin/env sh

distribName=$(lsb_release -si)
currentKernelVersion=$(uname -r | cut -d. -f1,2 | tr -d .)
if [ $distribName = Ubuntu ] && [ $currentKernelVersion -lt 44 ];then
	#sudo apt install -V linux-headers-virtual-lts-xenial linux-image-virtual-lts-xenial linux-image-extra-virtual-lts-xenial
	sudo apt install -V linux-generic-lts-xenial linux-headers-generic-lts-xenial linux-image-generic-lts-xenial linux-image-extra-virtual-lts-xenial
fi
