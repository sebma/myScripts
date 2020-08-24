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
		appList="mbuntu-y-ithemes-v4 mbuntu-y-icons-v4 mbuntu-y-bscreen-v4 mbuntu-y-lightdm-v4 slingscold indicator-synapse libreoffice-style-sifr appmenu-qt appmenu-qt5 plasma-widget-menubar"
		cd && wget -O config.sh http://drive.noobslab.com/data/Mac-14.10/config.sh
		chmod +x config.sh;./config.sh
		;;
	15.04) appList="mbuntu-y-ithemes-v5 mbuntu-y-icons-v5 slingscold mutate libreoffice-style-sifr mbuntu-y-lightdm-v5";;
	15.10) appList="macbuntu-ithemes-v6 macbuntu-icons-v6 slingscold mutate plank macbuntu-plank-theme-v6 libreoffice-style-sifr macbuntu-lightdm-v6 macbuntu-bscreen-v6";;
	16.04) appList="macbuntu-os-ithemes-lts-v7 slingscold albert libreoffice-style-sifr plank macbuntu-os-plank-theme-lts-v7 macbuntu-os-bscreen-lts-v7 macbuntu-os-lightdm-lts-v7";;
	16.10) appList="macbuntu-os-icons-lts-v8 macbuntu-os-ithemes-lts-v8 slingscold albert libreoffice-style-sifr plank macbuntu-os-plank-theme-lts-v8 macbuntu-os-bscreen-lts-v8 macbuntu-os-lightdm-lts-v8";;
	17.04) appList="macbuntu-os-icons-lts-v9 macbuntu-os-ithemes-lts-v9 slingscold albert libreoffice-style-sifr plank macbuntu-os-plank-theme-lts-v9 macbuntu-os-bscreen-lts-v9 macbuntu-os-lightdm-lts-v9";;
	17.10) appList="macbuntu-os-icons-lts-v10 macbuntu-os-ithemes-lts-v10 slingscold albert libreoffice-style-sifr plank macbuntu-os-plank-theme-lts-v10 macbuntu-os-bscreen-lts-v10 macbuntu-os-lightdm-lts-v10";;
	18.04) appList="macbuntu-os-icons-lts-v1804 macbuntu-os-ithemes-lts-v1804 slingscold albert libreoffice-style-sifr plank macbuntu-os-plank-theme-lts-v1804 macbuntu-os-bscreen-lts-v1804 macbuntu-os-lightdm-lts-v1804";;
esac

set -x
sudo apt install -V $appList $@
set +x
