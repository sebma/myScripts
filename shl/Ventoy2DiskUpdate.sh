#!/usr/bin/env bash

scriptDir=$(dirname $0)
scriptDir=$(cd $scriptDir;pwd)
app=ventoy
Ventoy2DiskScript=/opt/$app/Ventoy2Disk.sh
gitHubURL=https://github.com
gitHubAPIURL=https://api.github.com
gitHubUser=ventoy
gitHubRepo=Ventoy
gitHubAPIRepoURL=$gitHubAPIURL/repos/$gitHubUser/$gitHubRepo
ventoyLatestRelease=$(git ls-remote --tags --refs --sort=-version:refname https://github.com/$gitHubUser/$gitHubRepo | awk -F/ '{print gensub("^v","",1,$NF);exit}')
Ventoy2DiskLatestGitHubReleaseURL=$(curl -s $gitHubAPIRepoURL/releases |  jq -r '.[0].assets[] | select( .content_type == "application/x-gzip" ).browser_download_url')

curl -s "$Ventoy2DiskLatestGitHubReleaseURL" | tar -C /tmp -xz
chmod +x /tmp/ventoy-$ventoyLatestRelease/tool/xzcat
sudo mkdir -pv /opt/ventoy
rsync="$(which rsync) -uth -P -z --skip-compress=$RSYNC_SKIP_COMPRESS_LIST"
cp2ext234="$rsync -ogpuv -lSH"
time sudo $cp2ext234 -r /tmp/ventoy-$ventoyLatestRelease/* /opt/ventoy
sudo chown root -R /opt/ventoy/*
sudo rm -fr /tmp/ventoy-$ventoyLatestRelease/

cd /opt/ventoy/ && sudo ./Ventoy2Disk.sh -u "$@"
