#!/bin/bash

PackagesDevice=""
srcListFile=/etc/apt/sources.list
PackagesSrcDir=/var/cache/apt/archives
Distrib=jaunty

read -p "Which partition of device is used to backup the downloaded package, (example sdc3): " PackagesDevice

echo $PackagesDevice | egrep "^(h|s)d[a-h][1-9]$" >/dev/null || {
  echo $PackagesDevice does not exist ! 2>&1
  exit 1
}

PackagesDevice=/dev/$PackagesDevice
[ "`id -u`" -ne "0" ] && echo sudo bash

PackagesDir=/media/Packages
mkdir $PackagesDir
mount $PackagesDevice $PackagesDir
cd $PackagesDir || exit 2

function downloadPackage()
{
  packageName=$1

  apt-get -dV install $packageName
  mkdir -p $packageName/common
  mv $PackagesSrcDir/lib*.deb $packageName/common
  mv $PackagesSrcDir/*.deb $packageName
  sync
}

function installPackage()
{
  packageName=$1

  apt-get -yV install $packageName
  rm $PackagesSrcDir/*.deb
  sync
}

for package in xubuntu-desktop lxde simple-ccsm
do
  installPackage $package
done

registry="libssl-dev chntpw registry-tools reglookup"
mkdir registry && cd registry
for package in $registry
do
  installPackage $registry
done
cd ..

system="acpi alien clamav clamav-daemon clamtk gmountiso gnome-schedule gpm hardinfo hwinfo hplip-gui mc ntp python-qt4 lshw-gtk quicksynergy synergy lsscsi uck vim tree pstree"
mkdir system && cd system
for package in $system
do
  installPackage $package
done
cd ..

network="curlftpfs iftop network-manager nmap ntlmaps putty putty-tools sshfs tcptraceroute"
mkdir network && cd network
for package in $network
do
  installPackage $package
done
cd ..

virtualisation="qemu kvm ubuntu-virt-mgmt ubuntu-virt-server ubuntu-vm-builder python-vm-builder"
mkdir virtualisation && cd virtualisation
for package in $virtualisation
do
  installPackage $package
done
cd ..

docks="cairo-dock cairo-dock-plug-ins awn-manager simdock"
mkdir docks && cd docks
for package in $docks
do
  installPackage $package
done
cd ..

multimedia="amsn avinfo audacity avidemux avidemux-cli exif flashplugin-installer nautilus-cd-burner nautilus-image-converter squash mencoder pytube mhwaveedit mplayer smplayer mediainfo mediainfo-gui gtkpod ifuse"
mkdir multimedia && cd multimedia
for package in $multimedia
do
  installPackage $package
done
cd ..

office="evince cups-pdf pdfedit"
mkdir office && cd office
for package in $office
do
  installPackage $package
done
cd ..

firefox_plugins="evince mozplugger mozilla-mplayer swfdec-mozilla mozilla-plugin-gnash"
mkdir firefox_plugins && cd firefox_plugins
for package in $firefox_plugins
do
  installPackage $package
done
cd ..

