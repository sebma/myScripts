#!/usr/bin/env bash

ubuntuSources=/etc/apt/sources.list
grep -q universe $ubuntuSources   || sudo add-apt-repository universe -y
grep -q multiverse $ubuntuSources || sudo add-apt-repository multiverse -y
grep -q "^deb .*unit193/inxi" /etc/apt/sources.list.d/*.list || sudo add-apt-repository ppa:unit193/inxi -y
grep -q "^deb .*mikhailnov/hw-probe" /etc/apt/sources.list.d/*.list || sudo add-apt-repository ppa:mikhailnov/hw-probe -y
sudo apt update
sudo apt install -V inxi hw-probe
#sudo -E hw-probe -all -upload
#Request inventory ID:
#hw-probe -generate-inventory -email YOUR@EMAIL
#Mark your probes by this ID:
#sudo -E hw-probe -all -upload -i ID
