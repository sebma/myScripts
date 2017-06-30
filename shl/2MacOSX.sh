#!/usr/bin/env bash

ubuntuRelease=$(lsb_release -sr)
case $ubuntuRelease in
	16.04) ppaList=noobslab/macbuntu;;
	*) ppaList="noobslab/themes noobslab/apps";;
esac

for ppa in $ppaList
do
	sudo add-apt-repository -y ppa:$ppa
done
time sudo apt update

case $ubuntuRelease in
	14.04|14.10) appList="mbuntu-y-ithemes-v4 mbuntu-y-icons-v4 mbuntu-y-bscreen-v4 mbuntu-y-lightdm-v4 slingscold indicator-synapse libreoffice-style-sifr";;
	15.04) appList="mbuntu-y-ithemes-v5 mbuntu-y-icons-v5 slingscold mutate libreoffice-style-sifr mbuntu-y-lightdm-v5";;
	15.10) appList="macbuntu-ithemes-v6 macbuntu-icons-v6 slingscold mutate plank macbuntu-plank-theme-v6 libreoffice-style-sifr macbuntu-lightdm-v6 macbuntu-bscreen-v6";;
	16.04) appList="macbuntu-os-icons-lts-v7 macbuntu-os-ithemes-lts-v7 slingscold albert libreoffice-style-sifr plank macbuntu-os-plank-theme-lts-v7 macbuntu-os-bscreen-lts-v7 macbuntu-os-lightdm-lts-v7";;
esac

set -x
sudo apt install -V $appList $@
set +x
