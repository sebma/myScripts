#!/bin/sh
echo "=> Dechargement du pilote du chipset via82xx pour la carte son integree ..."
rmmod snd_via82xx
echo "=> MAJ du navigateur WEB + installation du francais pour ce navigateur ..."
dpkg -r iceweasel-l10n-fr iceweasel-l10n-de
cd ./DebianPackages
dpkg -i --force-confold iceweasel-l10n-fr_2*.deb
dpkg -i --force-confold jhead*.deb *lame*.deb p7zip*.deb unrar*.deb

#echo "=> Installation des paquets Debian via Internet ('apt-get update' doit avoir ete preallablement fait !!!) ..."
#time apt-get --yes install debian-multimedia-keyring tcptraceroute
#time apt-get --yes install lame exiv2 unrar twolame bittorrent-gui
cd -
echo "=> FIN d'Installation des paquets Debian via Internet."

