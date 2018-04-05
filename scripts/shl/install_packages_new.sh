#!/bin/sh
rmmod snd_via82xx
apt-get --yes remove iceweasel
echo "=> MAJ de la base de donnees des paquets Debian via Internet ..."
apt-get update
echo "=> Installation des paquets Debian via Internet ..."
apt-get --yes install lame
#apt-get --yes install xmms
#apt-get --yes install debian-multimedia-keyring
#apt-get --yes install iceweasel-l10n-fr lame
#apt-get --yes install exiv2 jhead krename gqview a2ps p7zip p7zip-full krusader a2ps unrar twolame
cd -

