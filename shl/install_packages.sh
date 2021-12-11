#!/usr/bin/env bash
echo "=> Dechargement du pilote du chipset via82xx pour la carte son integree ..."
rmmod snd_via82xx
echo "=> MAJ du navigateur WEB + installation du francais pour ce navigateur ..."
dpkg -r iceweasel-l10n-fr iceweasel-l10n-de
cd ./DebianPackages
dpkg -i --force-confold iceweasel-l10n-fr_2*.deb
dpkg -i --force-confold *lame*.deb unrar*.deb xmms*.deb jhead*.deb p7zip*.deb

#time apt-get --yes install debian-multimedia-keyring tcptraceroute
#time apt-get --yes install lame exiv2 krename gqview krusader unrar twolame bittorrent-gui bittorrent
#time apt-get --yes install a2ps
cd -

echo "=> FIN d'Installation des paquets Debian via Internet."

