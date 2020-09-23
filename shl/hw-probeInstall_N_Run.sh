#!/usr/bin/env bash

ubuntuSources=/etc/apt/sources.list
grep -q universe $ubuntuSources   || sudo add-apt-repository universe -y
grep -q multiverse $ubuntuSources || sudo add-apt-repository multiverse -y
sudo add-apt-repository ppa:unit193/inxi -y
sudo add-apt-repository ppa:mikhailnov/hw-probe -y
sudo apt-get update
sudo apt-get install hw-probe --no-install-recommends -y
sudo -E hw-probe -all -upload
