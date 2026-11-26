#!/usr/bin/env bash

cat <<EOF | sudo tee /etc/apt/preferences.d/vlc-ubuntuhandbook1-ppa
Package: vlc* libvlc*
Pin: release o=LP-PPA-ubuntuhandbook1-vlc
Pin-Priority: 510
EOF
installPackagesFromRepo.sh ppa:ubuntuhandbook1/vlc vlc
