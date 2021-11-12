#!/usr/bin/env bash

scriptDir=$(dirname $0)
scriptDir=$(cd $scriptDir;pwd)
app=freeTube
gitHubURL=https://github.com
gitHubAPIURL=https://api.github.com
gitHubUser=FreeTubeApp
gitHubRepo=FreeTube
gitHubAPIRepoURL=$gitHubAPIURL/repos/$gitHubUser/$gitHubRepo
freeTubeLatestGitHubReleaseURL=$(curl -s $gitHubAPIRepoURL/releases | jq -r '.[0].assets[] | select(.name | contains("amd64.deb")) | .browser_download_url')
freeTubeLatestGitHubReleaseTag=$(curl -s $gitHubAPIRepoURL/releases | jq -r '.[0].tag_name' | sed 's/v//;s/-beta//')
freeTubeInstalledVersion=$(dpkg-query --showformat='${Version}' -W freetube)
if [ "$freeTubeLatestGitHubReleaseTag" != "$freeTubeInstalledVersion" ];then
	freeTubeLatestGitHubReleaseName=$(basename $freeTubeLatestGitHubReleaseURL)
	wget -O $freeTubeLatestGitHubReleaseName "$freeTubeLatestGitHubReleaseURL"
	sudo gdebi -n $freeTubeLatestGitHubReleaseName && rm -v $freeTubeLatestGitHubReleaseName
fi
