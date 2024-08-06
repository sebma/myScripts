#!/usr/bin/env bash

architecture=$(uname -m)
case $architecture in
	x86_64) arch=amd64;;
	i686)   arch=i386; echo "=> FreeTube does not support $architecture architectures." >&2;exit 1;;
	*) echo "=> Unsupported architecture.";exit;;
esac

scriptDir=$(dirname $0)
scriptDir=$(cd $scriptDir;pwd)
scriptBaseName=${0##*/}

app=freeTube
protocol=https
gitHubURL=github.com
gitHubAPIURL=api.$gitHubURL
gitHubUser=FreeTubeApp
gitHubRepo=FreeTube
gitHubAPIRepoURL=$gitHubAPIURL/repos/$gitHubUser/$gitHubRepo
type sudo >/dev/null 2>&1 && [ $(id -u) != 0 ] && groups | egrep -wq "sudo|adm|admin|root|wheel" && local sudo="command sudo" || local sudo=""

if ! type -P jq >/dev/null;then
	echo "=> $0 : ERROR : You need to first install jq." >&2
	exit 2
fi

osType=$(uname -s)
if [ $osType = Linux ];then
	distribID=$(source /etc/os-release;echo $ID)
	if echo $distribID | egrep "debian|ubuntu" -q;then
		isDebianLike=true
	fi
elif [ $osType = Darwin ];then
	brew upgrade freetube
	exit
fi

echo "=> Searching for the latest release on $protocol://$gitHubURL/$gitHubUser/$gitHubRepo ..."
freeTubeLatestRelease=$(\curl -qLs -H "Accept: application/vnd.github.v3+json" $protocol://$gitHubAPIRepoURL/tags | jq -r '.[0].name' | sed 's/v//;s/-beta//')
echo "=> Found the $freeTubeLatestRelease version."

freeTubeInstalledVersion=null
if echo $distribID | egrep "debian|ubuntu" -q;then
	isDebianLike=true
	freeTubeInstalledVersion=$(dpkg-query --showformat='${Version}' -W freetube 2>/dev/null)
fi

if [ "$freeTubeLatestRelease" = "$freeTubeInstalledVersion" ];then
	echo "=> [$scriptBaseName] INFO : You already have the latest release, which is $freeTubeLatestRelease."
else
	echo "=> Fetching the latest freetube package URL ..."
	if $isDebianLike;then
		freeTubeLatestGitHubReleaseURL=$(time \curl -qLs -H "Accept: application/vnd.github.v3+json" $protocol://$gitHubAPIRepoURL/releases | jq -r ".[0].assets[] | select( .name | contains( \"$arch.deb\") ) | .browser_download_url")
		set +x
		if [ -n "$freeTubeLatestGitHubReleaseURL" ];then
			echo "=> Downloading $freeTubeLatestGitHubReleaseURL ..."
			echo
			freeTubeLatestGitHubReleaseName=$(basename $freeTubeLatestGitHubReleaseURL)
			mkdir -pv ~/deb/freetube
			cd ~/deb/freetube
			time \wget -c -O $freeTubeLatestGitHubReleaseName "$freeTubeLatestGitHubReleaseURL"
			sudo apt install -V ./$freeTubeLatestGitHubReleaseName || rm -v ./$freeTubeLatestGitHubReleaseName
			sync
			cd - >/dev/null
		fi
	fi
fi
