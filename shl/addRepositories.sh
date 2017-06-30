#!/usr/bin/env bash

PackagesDevice=""
srcListFile=/etc/apt/sources.list
PackagesSrcDir=/var/cache/apt/archives
Distrib=`lsb_release -rs`

function addRepostory()
{
  url=$1
  repositName=$2
  grep -q "deb $url $Distrib $repositName" $srcListFile || echo deb $url $Distrib $repositName >> $srcListFile
}

function addRepostorySrc()
{
  url=$1
  repositName=$2
  grep -q "deb.src $url $Distrib $repositName" $srcListFile || { 
    echo deb-src $url $Distrib $repositName >> $srcListFile
    echo >> $srcListFile
  }
}

[ $Distrib -ge 9.04 ] && {
  urlListMain="http://ppa.launchpad.net/siretart/ppa/ubuntu/" #Pour downgrader le driver XOrg Intel vers la version 1.4
} || {
  addRepostory http://repository.cairo-dock.org/ubuntu/ cairo-dock
  urlListMain="http://ppa.launchpad.net/rvm/mplayer/ubuntu/ http://ppa.launchpad.net/amule-releases/ppa/ubuntu/ http://ppa.launchpad.net/bjfs/ppa/ubuntu/ http://ppa.launchpad.net/pidgin-developers/ppa/ubuntu/ http://ppa.launchpad.net/shiki/mediainfo/ubuntu/ http://ppa.launchpad.net/siretart/ppa/ubuntu/"
}

for url in $urlListMain
do
  addRepostory $url main 
  addRepostorySrc $url main 
done

#Cas ou le nom du depot n'est pas main, en theorie on pourrait faire une boucle "for" sur deux parametre URL + nomDepot
addRepostory http://packages.medibuntu.org/ "free non-free"

exit 0
