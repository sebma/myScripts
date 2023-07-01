#!/usr/bin/env bash

distrib=$(source /etc/os-release;echo $ID)
if [ $distrib != ubuntu ];then
	echo "=> ERROR : This script is for Ubuntu only" >&2
	exit 1
fi

wget https://raw.githubusercontent.com/pimlie/ubuntu-mainline-kernel.sh/master/ubuntu-mainline-kernel.sh
sudo chmod +x ubuntu-mainline-kernel.sh
sudo install -vpm 755 ubuntu-mainline-kernel.sh /usr/local/bin/
#sudo ubuntu-mainline-kernel.sh -i
ubuntu-mainline-kernel.sh -h
