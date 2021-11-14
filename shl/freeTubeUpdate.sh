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
protocol=https
gitHubURL=github.com
gitHubAPIURL=api.$gitHubURL
gitHubUser=FreeTubeApp
gitHubRepo=FreeTube
gitHubAPIRepoURL=$gitHubAPIURL/repos/$gitHubUser/$gitHubRepo

freeTubeLatestGitHubReleaseTag=$(\curl -Ls $protocol://$gitHubAPIRepoURL/releases | jq -r '.[0].tag_name' | sed 's/v//;s/-beta//')
freeTubeInstalledVersion=$(dpkg-query --showformat='${Version}' -W freetube)
if [ "$freeTubeLatestGitHubReleaseTag" != "$freeTubeInstalledVersion" ];then
	freeTubeLatestGitHubReleaseURL=$(\curl -Ls $protocol://$gitHubAPIRepoURL/releases | jq -r ".[0].assets[] | select( .name | contains( \"$arch.deb\") ) | .browser_download_url")
	if [ -n "$freeTubeLatestGitHubReleaseURL" ];then
		freeTubeLatestGitHubReleaseName=$(basename $freeTubeLatestGitHubReleaseURL)
		wget -O $protocol://$freeTubeLatestGitHubReleaseName "$freeTubeLatestGitHubReleaseURL"
		sudo gdebi -n $freeTubeLatestGitHubReleaseName && rm -v $freeTubeLatestGitHubReleaseName
	fi
fi
