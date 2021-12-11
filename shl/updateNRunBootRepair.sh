#!/usr/bin/env bash

setxkbmap fr
sudo apt-get clean
sudo apt-get autoremove -y
sudo apt install software-properties-common man-db vim -y
sudo add-apt-repository ppa:yannubuntu/boot-repair -y
sudo apt update -q
sudo apt install boot-info boot-repair boot-sav boot-sav-extra os-uninstaller -y
#sudo apt-get install -y --force-yes mdadm --no-install-recommends

#gksu boot-repair
