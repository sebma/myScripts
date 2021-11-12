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
freeTubeLatestGitHubReleaseName=$(basename $freeTubeLatestGitHubReleaseURL)
freeTubeLatestGitHubReleaseTag=$(curl -s $gitHubAPIRepoURL/tags | jq -r '.[0].name')
wget -O $freeTubeLatestGitHubReleaseName "$freeTubeLatestGitHubReleaseURL"
sudo gdebi -n $freeTubeLatestGitHubReleaseName && rm -v $freeTubeLatestGitHubReleaseName
