#!/usr/bin/env bash

cat <<EOF | sudo tee /etc/apt/preferences.d/ffmpeg6-ubuntuhandbook1-ppa
Package: ffmpeg*
Pin: release o=LP-PPA-ubuntuhandbook1-ffmpeg6
Pin-Priority: 510
EOF
installPackagesFromRepo.sh ppa:ubuntuhandbook1/ffmpeg6 ffmpeg
