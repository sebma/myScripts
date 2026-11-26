#!/usr/bin/env bash

wget -qO- 'http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x6888550b2fc77d09' | sudo tee /etc/apt/trusted.gpg.d/songrec.asc
sudo apt-add-repository ppa:marin-m/songrec -y -u
sudo apt install songrec -V -y
