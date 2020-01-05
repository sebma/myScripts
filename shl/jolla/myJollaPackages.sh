#!/usr/bin/env bash

LANG=C
set -o nounset
set -o errexit

os=$(awk -F= '/^ID=/{print$2}' /etc/os-release)
if [ $os != sailfishos ]
then
	echo "=> ERROR : $0 must be run on a SailfishOS machine." 1>&2
	exit 1
fi

refreshRepos=0
if ! which sudo >/dev/null 2>&1
then
	set -x
	if ! ssu repos | egrep -q mer-tools.*https?://releases.jolla.com/releases/.*mer-tools
	then
		ssu addrepo mer-tools
		refreshRepos=1
		ssu updaterepos
	fi

	devel-su sh -xc "pkcon -v refresh;pkcon install -y zypper sudo;sed -ri '/%sudo/s/^# //' /etc/sudoers;groupadd sudo;usermod -a -G sudo $USER" # Allow members of group sudo to execute any command
	refreshRepos=0

	rpm -q sudo && exit
	set +x
fi

echo "=> Configuring Europe/Paris timezone ..."
sudo ln -vfs /usr/share/zoneinfo/Europe/Paris /etc/localtime

echo "=> Enabling and starting sshd ..."
sudo systemctl enable sshd.service
sudo systemctl start sshd.service

bash4="$(which bash4 2>/dev/null)"
if [ -z "$bash4" ]
then
	echo "=> Configuring bash4 for $USER ..."
	grep -q bash4 /etc/shells || echo $bash4 | sudo tee -a /etc/shells
	if ! getent passwd $USER | grep -q $bash4
	then
		sudo chsh -s $bash4 $USER
		exit
	fi
fi

for repo in Schturman basil NielDK V10lator edgley llelectronics matolainen equeim inte BloodyFoxy yoktobit nodevel Schturman steffen_f Morpog rzr lourens rcolistete osetr
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

test "$refreshRepos" = 1 && sudo pkcon -v refresh && sudo zypper -v refresh
refreshRepos=0

if ! rpm -q hebrewvkb-simple >/dev/null;then
	echo "=> Installing hebrewvkb-simple ..."
	sudo zypper -v install hebrewvkb-simple
	rpm -q hebrewvkb-simple >/dev/null && systemctl --user restart maliit-server # Restart the keyboard service
fi

echo "=> Installing cups ..."
\wget -O service-script https://www.dropbox.com/s/21ah44ummyn8rdw/service-script.sh
sudo mkdir -vp /usr/local/sbin/
sudo install -vm755 ./service-script /usr/local/sbin/
rm ./service-script
sudo ln -vs /usr/local/sbin/service-script /sbin/service
sudo zypper -v install cups
groups | grep -wq lp || { sudo groupadd lpadmin; sudo usermod -a -G lp,lpadmin $USER; exit; }
sudo systemctl restart cups
systemctl status cups
echo "=> Now you have to add a printer with <lpadmin>."

systemctl --user restart timed-qt5.service # Restart the "timed-qt5" service
systemctl --user status  maliit-server timed-qt5.service sshd.service | egrep ' - |Active:'

jollaStorePackages="speex-tools findutils harbour-situations2application situations-sonar sailfish-utilities sqlite harbour-barcode harbour-file-browser python pciutils curl yum harbour-unplayer harbour-maxvol harbour-bibleme harbour-recorder git-minimal make cmake gcc gettext nano mutt harbour-ipaddress perl ruby perl-CPAN htop"
for package in $jollaStorePackages
do
	rpm -q $package || sudo zypper -v install $package
#	zypper info $package | grep Repository
done
echo

jollaOptionalPackages="gzip jolla-startupwizard-tutorial"

openreposStorePackages="situationreboot harbour-storeman harbour-qrscany bash4 wget aria2 bash-completion harbour-reboot mutt parted man-db less vim sd-utils-0.3.0.1-2 harbour-unplayer harbour-maxvol nano ffmpeg-tools ruby ipython python-matplotlib python-sympy harbour-ytplayer harbour-videoPlayer-1.7-1 android-chatmail-notification-0.2-7"
for package in $openreposStorePackages
do
	rpm -q $package || sudo zypper -v install $package
#	zypper info $package | grep Repository
done

currentOSVersion=$(version | awk '{print$3}')
[ $currentOSVersion ">" 1.1.2.15 ] && for package in harbour-roamer gcc-c++
do
	rpm -q $package || sudo zypper -v install $package
done

echo "=> Updating installed packages ..." >&2
sudo zypper -v update
echo

echo "=> Installing the pip3 tool ..."
which pip3 >/dev/null 2>&1 || curl -s https://bootstrap.pypa.io/get-pip.py | sudo -H python3
echo

echo "=> Installing the speedtest tool ..."
pip3 show speedtest-cli >/dev/null || sudo -H $(which pip3) install speedtest-cli
echo

echo "=> Installing a few AlienDalvik Android apps ..."
echo
echo "=> Installing FDroid ..."
grep -qri Exec=.*fdroid /usr/share/applications/ && echo "=> FDroid  is already instaled." >&2 || {
	echo "=> Downloading and installing FDroid ..." >&2
	wget --no-check-certificate -nvc https://f-droid.org/FDroid.apk && apkd-install FDroid.apk && rm -vf FDroid.apk
}

echo "=> Installing APToide ..."
grep -qri Exec=.*aptoide /usr/share/applications/ && echo "=> APToide is already instaled." >&2 || {
	echo "=> Downloading and installing APToide ..." >&2
	#apToideURL=$(curl -s "http://m.aptoide.com/installer/thank-you?utm_source=google&utm_campaign=(organic)&utm_medium=organic&entry_point=installer_mobile" | sed -n "/\.apk/s/.*src=.//;s/\.apk.*/.apk/;/\.apk/p")
	apToideURL=$(curl -s "http://m.aptoide.com/installer/thank-you?utm_source=google&utm_campaign=(organic)&utm_medium=organic&entry_point=installer_mobile" | sed -n '/\.apk/s/^.*href="//;/\.apk/s/\.apk.*/.apk/;/\.apk/p')
	echo "=> apToideURL = $apToideURL"
	curl -#OC- "$apToideURL" && wget --no-check-certificate -nvc $apToideURL && apkd-install $(basename $apToideURL) && rm -vf $(basename "$apToideURL")
}

echo "=> Installing MySword v6.6 ..."
grep -qri Exec=.*mysword /usr/share/applications/ && echo "=> MySword is already instaled." >&2 || {
	echo "=> Downloading and installing MySword ..." >&2
	mySwordURL=https://mysword-bible.info/download/mysword4android-6.6.apk
	wget --no-check-certificate -nvc $mySwordURL && apkd-install $(basename $mySwordURL) && rm -vf mysword4android-6.6.apk
}

sync
