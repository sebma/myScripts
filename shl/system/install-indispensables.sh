#!/usr/bin/env bash

sudo apt install -V apt-file aptitude aria2 bind9-dnsutils curl dconf-editor dfc dlocate fd-find gh git glances htop hub jq lynx mc neofetch plocate ppa-purge pv rclone ripgrep rsync vim w3m wget xclip xsel
sudo snap install yq
sudo apt install -V doublecmd-gtk geany gnome-tweaks keepassxc libreoffice
dpkg -s dra >/dev/null || { wget -c -nv https://github.com/devmatteini/dra/releases/latest/download/dra_0.6.2-1_amd64.deb && sudo apt install -V ./dra_0.6.2-1_amd64.deb && rm ./dra_0.6.2-1_amd64.deb; }
# sudo apt install -V vlc mpv
sudo systemctl daemon-reload
sudo apt update
sudo apt-file update
sudo updatedb
sudo update-dlocatedb

dpkg -s glances | grep installed -q && systemctl -at service | grep glances -q && sudo systemctl stop glances && sudo systemctl disable glances
