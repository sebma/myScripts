#!/usr/bin/env bash

cat <<EOF | sudo tee /etc/apt/preferences.d/ffmpeg7-ubuntuhandbook1-ppa
Package: ffmpeg*
Pin: release o=LP-PPA-ubuntuhandbook1-ffmpeg7
Pin-Priority: 510
EOF
installPackagesFromRepo.sh ppa:ubuntuhandbook1/ffmpeg7 ffmpeg
