#!/usr/bin/env bash

DISTRO=$(lsb_release -sc)
curl -# -Sf https://repo.waydro.id/waydroid.gpg | sudo apt-key add -
echo "deb https://repo.waydro.id/ $DISTRO main" | sudo tee /etc/apt/sources.list.d/waydroid.list
sudo apt update
sudo apt install ca-certificates waydroid -V
sudo waydroid init
echo "=> Check the /var/lib/waydroid filesystem ."
