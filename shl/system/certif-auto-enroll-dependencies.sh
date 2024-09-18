#!/usr/bin/env bash

if ! which getcert &>/dev/null;then
	echo "==> Installing adsys certmonger python3-cepces ..."
	sudo apt-get install adsys certmonger python3-cepces -y >/dev/null
fi
echo "=> adsysctl update ..."
sudo adsysctl update -v -m
echo "=> getcert list"
sudo getcert list
echo "=> getcert list-cas"
sudo getcert list-cas
echo "=> Listing last $LINES lines of /var/log/cepces/cepces.log log file :"
sudo tail -$LINES /var/log/cepces/cepces.log
# xdg-open https://canonical-adsys.readthedocs-hosted.com/en/stable/explanation/certificates
