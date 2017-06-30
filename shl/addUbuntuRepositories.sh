#!/usr/bin/env sh

type lsb_release >/dev/null 2>&1 || {
  echo "=> ERROR: lsb_release is not present !" >&2
  exit 1
}

srcListFile=/etc/apt/sources.list
DistribName=`lsb_release -si`
DistribCode=`lsb_release -sc`
DistribVersion=`lsb_release -sr`

ppaRepositoryList="rvm/smplayer amule-releases/ppa bjfs/ppa pidgin-developers/ppa shiki/mediainfo pmcenery/ppa qmagneto/ppa mozillateam/firefox-stable cairo-dock-team/ppa"
[ "$DistribName" = "Ubuntu" ] && {
  expr $DistribVersion '>' 9.04 >/dev/null && {
    ppaRepositoryList="$ppaRepositoryList gdm2setup/gdm2setup"
    for repo in $ppaRepositoryList
    do
      sudo add-apt-repository ppa:$repo
    done
    sudo apt-get update >/dev/null
  } || {
    addRepostory()
    {
      url=$1
      repositName=$2
      grep -q "deb $url $DistribCode $repositName" $srcListFile || echo deb $url $DistribCode $repositName | sudo tee -a $srcListFile
    }

    addRepostorySrc()
    {
      url=$1
      repositName=$2
      grep -q "deb.src $url $DistribCode $repositName" $srcListFile || { 
        echo deb-src $url $DistribCode $repositName | sudo tee -a $srcListFile
        echo | sudo tee -a $srcListFile
      }
    }

    [ $DistribVersion = 9.04 ] && {
      ppaRepositoryList="rvm/mplayer $ppaRepositoryList siretart/ppa"
    } || {
      ppaRepositoryList="rvm/mplayer $ppaRepositoryList schaumkeks/ppa"
    }

    for ppa in $ppaRepositoryList
    do
      url="http://ppa.launchpad.net/$ppa/ubuntu"
      addRepostory $url main
      addRepostorySrc $url main
    done

    #Cas ou le nom du depot n'est pas main, en theorie on pourrait faire une boucle "for" sur deux parametre URL + nomDepot
    addRepostory http://packages.medibuntu.org/ "free non-free"
    sudo apt-get install add-apt-key >/dev/null && sudo apt-get update 2>&1 >/dev/null | awk '/PUBKEY/{print $NF}' | xargs -rtL1 sudo add-apt-key
  }
}

exit 0

