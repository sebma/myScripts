#!/usr/bin/env bash

distribName=$(lsb_release -si | awk '{print tolower($0)}')

# cf. https://github.com/eLvErDe/hwraid and https://hwraid.le-vert.net/wiki/DebianPackages
raidDriversList=$(\lspci -d::0104 -k | awk '/Kernel driver in use/{print\$NF}' | grep -vw ahci | head -1)
case $raidDriversList in
	hpsa)
		installPackagesFromRepo.sh "deb http://hwraid.le-vert.net/$distribName $(lsb_release -sc) main" hpacucli
#		sudo add-apt-repository "deb http://hwraid.le-vert.net/ubuntu focal main"
	;;
	megaraid_sas) installPackagesFromRepo.sh "deb http://hwraid.le-vert.net/$distribName $(lsb_release -sc) main" megacli megaclisas-status;;
	*) echo "=> $raidDriversList is not supported yes" >&2;exit 1;;
esac
