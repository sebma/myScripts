#!/usr/bin/env bash

ubuntuRelease=$(lsb_release -sr)
ubuntuCodeName=$(lsb_release -sc)
if ! dpkg -s packages-microsoft-prod &>/dev/null;then
	wget https://packages.microsoft.com/config/ubuntu/$ubuntuRelease/packages-microsoft-prod.deb
	sudo apt install -V ./packages-microsoft-prod.deb
	rm -v ./packages-microsoft-prod.deb
	sudo sed -i "/$ubuntuRelease/s/$ubuntuRelease/24.04/;/$ubuntuCodeName/s/$ubuntuCodeName/noble/" /etc/apt/sources.list.d/microsoft-prod.list
	curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg --yes
fi

arch=$(dpkg --print-architecture)
if ! dpkg -s ms-teams &>/dev/null;then
	echo "deb [arch=$arch signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/repos/ms-teams stable main" \
| sudo tee /etc/apt/sources.list.d/ms-teams.list
	apt policy ms-teams | grep 'Candidate:' -q || sudo apt update
	sudo apt install -V ms-teams
fi
