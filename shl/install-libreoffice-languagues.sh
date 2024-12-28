#!/usr/bin/env bash
set -u
declare {isDebian,isRedHat}Like=false

test $(id -u) == 0 && sudo="" || sudo=sudo

echo $OSTYPE | grep -q android && osFamily=Android || osFamily=$(uname -s)

libreofficeVersion=$(soffice --version | awk '/LibreOffice/{print$2}' | cut -d. -f1-3)

if [ $osFamily == Linux ];then
	distribID=$(source /etc/os-release;echo $ID)
	majorNumber=$(source /etc/os-release;echo $VERSION_ID | cut -d. -f1)

	if   echo $distribID | egrep "centos|rhel|fedora" -q;then
		isRedHatLike=true
		packageType=rpm
	elif echo $distribID | egrep "debian|ubuntu" -q;then
		isDebianLike=true
		packageType=deb
		if echo $distribID | egrep "ubuntu" -q;then
			isUbuntuLike=true
		fi
	fi

	languagePackFile=LibreOffice_${libreofficeVersion}_${osFamily}_x86-64_${packageType}_langpack_fr.tar.gz
	wget https://download.documentfoundation.org/libreoffice/stable/$libreofficeVersion/$packageType/x86_64/$languagePackFile
	if [ $isUbuntuLike ];then
		:
	fi
elif [ $osFamily == Darwin ];then # https://osxdaily.com/2023/10/13/native-macos-docker-containers-are-now-possible
	packageType=mac
	osFamily=MacOS
	languagePackFile=LibreOffice_${libreofficeVersion}_${osFamily}_x86-64_langpack_fr.dmg
	$brew upgrade libreoffice-language-pack
	wget https://download.documentfoundation.org/libreoffice/stable/$libreofficeVersion/$packageType/x86_64/$languagePackFile
	:
fi
rm -iv $languagePackFile
