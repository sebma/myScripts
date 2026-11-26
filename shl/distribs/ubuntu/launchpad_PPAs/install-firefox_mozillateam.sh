#!/usr/bin/env bash

grep o=LP-PPA-mozillateam /etc/apt/preferences.d/* -q || cat <<EOF | sudo tee /etc/apt/preferences.d/firefox-mozillateam-ppa
Package: firefox firefox-*
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 510
EOF
installPackagesFromRepo.sh ppa:mozillateam/ppa firefox firefox-locale-en firefox-locale-fr
