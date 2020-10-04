#!/usr/bin/env bash

ubuntuRelease=$(\lsb_release -sr)
case $ubuntuRelease in
	16.04|16.10|17.04|17.10|18.04) ppaList=noobslab/macbuntu;;
	14.04|14.10|15.04|15.10) ppaList="noobslab/themes noobslab/apps";;
	13.10) ppaList="noobslab/themes noobslab/apps docky-core/ppa";;
	12.04|12.10|13.04) ppaList="noobslab/themes cairo-dock-team/ppa";;
esac

for ppa in $ppaList
do
	grep -q $ppa /etc/apt/sources.list.d/*.list || sudo add-apt-repository -y ppa:$ppa
done
time sudo apt update

case $ubuntuRelease in
	14.04|14.10)
		cd && wget -O config.sh http://drive.noobslab.com/data/Mac-14.10/config.sh
		chmod +x config.sh;./config.sh
		version=v4;;
	15.04) version=v5;;
	15.10) version=v6;;
	16.04) version=lts-v7;;
	16.10) version=lts-v8;;
	17.04) version=v9;;
	17.10) version=v10;;
	18.04|18.10) version=v1804;;
esac

case $ubuntuRelease in
	14.04|14.10) appList="mbuntu-y-ithemes-$version mbuntu-y-icons-$version mbuntu-y-bscreen-$version mbuntu-y-lightdm-$version slingscold indicator-synapse libreoffice-style-sifr appmenu-qt appmenu-qt5 plasma-widget-menubar";;
	15.04) appList="mbuntu-y-ithemes-$version mbuntu-y-icons-$version slingscold mutate libreoffice-style-sifr mbuntu-y-lightdm-$version";;
	15.10) appList="macbuntu-ithemes-$version macbuntu-icons-$version slingscold mutate plank macbuntu-plank-theme-$version libreoffice-style-sifr macbuntu-lightdm-$version macbuntu-bscreen-$version";;
	16.04|16.10|17.04|17.10) appList="macbuntu-os-icons-$version macbuntu-os-ithemes-$version slingscold albert libreoffice-style-sifr plank macbuntu-os-plank-theme-$version macbuntu-os-bscreen-$version macbuntu-os-lightdm-$version";;
	18.04) appList="macbuntu-os-icons-$version macbuntu-os-ithemes-$version slingscold albert libreoffice-style-sifr plank macbuntu-os-plank-theme-$version";;
	18.10) appList="macbuntu-os-plank-theme-$version slingscold albert libreoffice-style-sifr plank";;
esac

set -x
sudo apt install -V $appList $@
dpkg -l | grep -q ^.i.*macbuntu-os-bscreen-lts-$version && sudo dpkg-reconfigure macbuntu-os-bscreen-lts-$version
set +x
