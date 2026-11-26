#!/usr/bin/env bash

sudo wget -O /usr/share/keyrings/newlifelinux.gpg http://ppa.newlifelinux.org/gpg.key
sudo echo "deb [arch=amd64 signed-by=/usr/share/keyrings/newlifelinux.gpg] http://ppa.newlifelinux.org/ubuntu/ noble main" | sudo tee /etc/apt/sources.list.d/newlife-noble.list
sudo apt update && sudo apt install -V rustdesk -y
