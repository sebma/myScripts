#!/usr/bin/env bash
echo "=> Installation des paquets contenus dans $PWD ..."
rmmod snd_via82xx
dpkg -r iceweasel-l10n-de iceweasel-l10n-fr iceweasel
dpkg -i --force-confold DebianPackages/iceweasel_2*.deb
dpkg -i --force-confold DebianPackages/debian-multimedia*.deb
dpkg -i --force-confold DebianPackages/p7z*.deb
dpkg -i --force-confold DebianPackages/jhead_2*.deb DebianPackages/gqview_2*.deb
dpkg -i --force-confold DebianPackages/libexiv2*.deb DebianPackages/exiv2*.deb
dpkg -i --force-confold DebianPackages/iceweasel-l10n-fr_2*.deb DebianPackages/krename*.deb
dpkg -i --force-confold DebianPackages/krusader*.deb DebianPackages/libkjsembed*.deb
dpkg -i --force-confold DebianPackages/emacsen-common*.deb DebianPackages/lame*.deb DebianPackages/xmms*.deb DebianPackages/gqview*.deb
dpkg -i --force-confold DebianPackages/a2ps*.deb DebianPackages/unrar*.deb DebianPackages/twolame*.deb
cd /usr/bin && ln -s lame-3.97 lame
#echo "=> MAJ de la base des paquets via Internet ..."
#apt-get update
cd -

