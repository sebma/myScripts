#!/usr/bin/env bash

architecture=$(uname -m)
case $architecture in
	x86_64) arch=amd64;;
	i686)   arch=i386;;
	*) echo "=> Unsupported architecture.";exit;;
esac

scriptDir=$(dirname $0)
scriptDir=$(cd $scriptDir;pwd)
app=freeTube
gitHubURL=https://github.com
gitHubAPIURL=https://api.github.com
gitHubUser=FreeTubeApp
gitHubRepo=FreeTube
gitHubAPIRepoURL=$gitHubAPIURL/repos/$gitHubUser/$gitHubRepo
freeTubeLatestGitHubReleaseURL=$(curl -s $gitHubAPIRepoURL/releases | jq -r ".[0].assets[] | select( .name | contains( \"$arch.deb\") ) | .browser_download_url")
freeTubeLatestGitHubReleaseTag=$(curl -s $gitHubAPIRepoURL/releases | jq -r '.[0].tag_name' | sed 's/v//;s/-beta//')
freeTubeInstalledVersion=$(dpkg-query --showformat='${Version}' -W freetube)
if [ "$freeTubeLatestGitHubReleaseTag" != "$freeTubeInstalledVersion" ];then
	freeTubeLatestGitHubReleaseName=$(basename $freeTubeLatestGitHubReleaseURL)
	wget -O $freeTubeLatestGitHubReleaseName "$freeTubeLatestGitHubReleaseURL"
	sudo gdebi -n $freeTubeLatestGitHubReleaseName && rm -v $freeTubeLatestGitHubReleaseName
fi
