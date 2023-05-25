#!/usr/bin/env sh

grep Kodi /etc/ufw/applications.d/* -q || cat <<EOF | sudo tee /etc/ufw/applications.d/kodi
[Kodi]
title=Kodi Media Center
description=Kodi, formerly known as XBMC Media Center, is a software media-player and entertainment hub for all your digital media.
# Ports specifiques a mon Kodi
ports=8080,9090,9777/tcp
EOF

for lan in 192.168.0.0/24 192.168.1.0/24;do
	for app in OpenSSH Kodi;do
		sudo ufw allow from $lan to any app $app
	done
done

sudo ufw enable
sudo ufw status
