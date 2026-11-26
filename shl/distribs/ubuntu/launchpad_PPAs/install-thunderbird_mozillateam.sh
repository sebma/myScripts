#!/usr/bin/env bash

cat <<EOF | sudo tee /etc/apt/preferences.d/thunderbird-mozillateam-ppa
Package: thunderbird thunderbird-*
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 510
EOF
installPackagesFromRepo.sh ppa:mozillateam/ppa thunderbird thunderbird-gnome-support thunderbird-locale-en-gb thunderbird-locale-en-us thunderbird-locale-en thunderbird-locale-fr
