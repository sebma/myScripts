#!/usr/bin/env bash

LANG=C
set -o nounset
set -o errexit

if ! which sudo >/dev/null 2>&1
then
	set -x
	if ! ssu repos | egrep -q mer-tools.*https?://releases.jolla.com/releases/.*mer-tools
	then
		ssu addrepo mer-tools
		ssu updaterepos
		refreshRepos=1
		devel-su sh -c "pkcon refresh;pkcon install -y sudo"
	else
		devel-su sh -c "pkcon install -y sudo"
	fi

	rpm -q sudo
	set +x
fi

if ! groups | grep -qw sudo
then
	devel-su sh -xc "groupadd sudo;usermod -aG sudo $USER" && exit
fi

getent passwd $USER | grep -q $(which bash4) || sudo chsh -s $(which bash4) $USER

refreshRepos=0
which zypper >/dev/null 2>&1 || sudo pkcon install zypper
for repo in basil NielDK V10lator edgley llelectronics matolainen equeim inte BloodyFoxy yoktobit nodevel Schturman steffen_f Morpog rzr lourens rcolistete osetr
do
	if ! ssu repos | egrep -q openrepos-$repo.*https?://sailfish.openrepos.net/$repo 
	then
		set -x
		ssu addrepo openrepos-$repo http://sailfish.openrepos.net/$repo/personal/main
		ssu updaterepos
		set +x
		refreshRepos=1
	fi	
done

test "$refreshRepos" = 1 && sudo pkcon refresh
jollaStorePackages="sailfish-utilities sqlite harbour-barcode harbour-file-browser python pciutils curl yum harbour-unplayer harbour-maxvol harbour-bibleme harbour-recorder git-minimal make cmake gcc gettext nano mutt harbour-ipaddress perl ruby perl-CPAN htop"
for package in $jollaStorePackages
do
	rpm -q $package || sudo zypper -v install $package
#	zypper info $package | grep Repository
done
echo

jollaOptionalPackages="gzip jolla-startupwizard-tutorial"

warehouseStorePackages="harbour-warehouse harbour-qrscany bash4 wget aria2 bash-completion harbour-reboot mutt parted man-db less vim sd-utils-0.3.0.1-2 harbour-unplayer harbour-maxvol nano ffmpeg ruby ipython python-matplotlib python-sympy harbour-ytplayer harbour-videoPlayer-1.7-1 android-chatmail-notification-0.2-7"
for package in $warehouseStorePackages
do
	rpm -q $package || sudo zypper -v install $package
#	zypper info $package | grep Repository
done

currentOSVersion=$(version | awk '{print$2}')
[ $currentOSVersion ">" 1.1.2.15 ] && for package in harbour-roamer gcc-c++
do
	rpm -q $package || sudo zypper -v install $package
done

echo "=> Updating installed packages ..." >&2
sudo zypper -v update

grep -qri Exec=.*fdroid /usr/share/applications/ && echo "=> FDroid  is already instaled." >&2 || {
	echo "=> Downloading and installing FDroid ..." >&2
	wget --no-check-certificate -nvc https://f-droid.org/FDroid.apk && apkd-install FDroid.apk && rm -vf FDroid.apk
}

grep -qri Exec=.*aptoide /usr/share/applications/ && echo "=> APToide is already instaled." >&2 || {
	echo "=> Downloading and installing APToide ..." >&2
	#apToideURL=$(curl -s "http://m.aptoide.com/installer/thank-you?utm_source=google&utm_campaign=(organic)&utm_medium=organic&entry_point=installer_mobile" | sed -n "/\.apk/s/.*src=.//;s/\.apk.*/.apk/;/\.apk/p")
	apToideURL=$(curl -s "http://m.aptoide.com/installer/thank-you?utm_source=google&utm_campaign=(organic)&utm_medium=organic&entry_point=installer_mobile" | sed -n '/\.apk/s/^.*href="//;/\.apk/s/\.apk.*/.apk/;/\.apk/p')
	echo "=> apToideURL = $apToideURL"
	curl -#OC- "$apToideURL" && wget --no-check-certificate -nvc $apToideURL && apkd-install $(basename $apToideURL) && rm -vf $(basename "$apToideURL")
}

grep -qri Exec=.*mysword /usr/share/applications/ && echo "=> MySword is already instaled." >&2 || {
	echo "=> Downloading and installing MySword ..." >&2
	mySwordURL=http://mysword-bible.info:8080/download/mysword4android-6.6.apk
	wget --no-check-certificate -nvc $mySwordURL && apkd-install $(basename $mySwordURL) && rm -vf mysword4android-6.6.apk
}

sync
