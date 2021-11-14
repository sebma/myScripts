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

echo "=> Searching for the latest release on $protocol://$gitHubURL/$gitHubUser/$gitHubRepo ..."
freeTubeLatestRelease=$(\curl -Ls $protocol://$gitHubAPIRepoURL/releases | jq -r '.[0].tag_name' | sed 's/v//;s/-beta//')
echo "=> Found the $freeTubeLatestRelease version."
freeTubeInstalledVersion=$(dpkg-query --showformat='${Version}' -W freetube 2>/dev/null)

if [ "$freeTubeLatestRelease" = "$freeTubeInstalledVersion" ];then
	echo "=> [$scriptBaseName] INFO : You already have the latest release, which is $freeTubeLatestRelease."
else
	freeTubeLatestGitHubReleaseURL=$(\curl -Ls $protocol://$gitHubAPIRepoURL/releases | jq -r ".[0].assets[] | select( .name | contains( \"$arch.deb\") ) | .browser_download_url")
	if [ -n "$freeTubeLatestGitHubReleaseURL" ];then
		freeTubeLatestGitHubReleaseName=$(basename $freeTubeLatestGitHubReleaseURL)
		wget -nv -O $freeTubeLatestGitHubReleaseName "$freeTubeLatestGitHubReleaseURL"
		sudo gdebi -n $freeTubeLatestGitHubReleaseName && rm -v $freeTubeLatestGitHubReleaseName
		sync
	fi
fi
