#!/usr/bin/env bash

ubuntuSources=/etc/apt/sources.list
grep -q universe $ubuntuSources   || sudo add-apt-repository universe
grep -q multiverse $ubuntuSources || sudo add-apt-repository multiverse
sudo add-apt-repository ppa:unit193/inxi
sudo add-apt-repository ppa:mikhailnov/hw-probe
sudo apt-get update
sudo apt-get install hw-probe --no-install-recommends
