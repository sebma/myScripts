#!/usr/bin/env bash

ubuntuRelease=$(lsb_release -sr)
ubuntuCodeName=$(lsb_release -sc)

wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
    | gpg --dearmor \
    | sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg

arch=$(dpkg --print-architecture)
if ! dpkg -s codium &>/dev/null;then
	echo -e 'Types: deb\nURIs: https://download.vscodium.com/debs\nSuites: vscodium\nComponents: main\nArchitectures: amd64 arm64\nSigned-by: /usr/share/keyrings/vscodium-archive-keyring.gpg' \
| sudo tee /etc/apt/sources.list.d/codium.sources
	apt policy codium | grep 'Candidate:' -q || sudo apt update
	sudo apt install -V codium
fi

#xdg-mime default code.desktop text/plain
#sudo update-alternatives --install $(type -P editor) editor $(which codium) 10
#sudo update-alternatives --set editor $(type -P codium)
