#!/usr/bin/env bash

ubuntuSources=/etc/apt/sources.list
grep -q universe $ubuntuSources   || sudo add-apt-repository universe -y
grep -q multiverse $ubuntuSources || sudo add-apt-repository multiverse -y
grep -q "^deb .*unit193/inxi" /etc/apt/sources.list.d/*.list || sudo add-apt-repository ppa:unit193/inxi -y
grep -q "^deb .*mikhailnov/hw-probe" /etc/apt/sources.list.d/*.list || sudo add-apt-repository ppa:mikhailnov/hw-probe -y
sudo apt-get update
sudo apt-get install inxi hw-probe --no-install-recommends -y
#sudo -E hw-probe -all -upload
