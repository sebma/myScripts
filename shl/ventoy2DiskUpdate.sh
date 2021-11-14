#!/usr/bin/env bash

scriptDir=$(dirname $0)
scriptDir=$(cd $scriptDir;pwd)
app=ventoy
ventoyROOT=/opt/$app
Ventoy2DiskScript=$ventoyROOT/Ventoy2Disk.sh
protocol=https
gitHubURL=github.com
gitHubAPIURL=api.$gitHubURL
gitHubUser=ventoy
gitHubRepo=Ventoy
gitHubAPIRepoURL=$gitHubAPIURL/repos/$gitHubUser/$gitHubRepo
#ventoyLatestRelease=$(git ls-remote --tags --refs --sort=-version:refname $protocol://$gitHubURL/$gitHubUser/$gitHubRepo | awk -F/ '{print gensub("^v","",1,$NF);exit}')
ventoyLatestRelease=$(\curl -Ls $protocol://$gitHubAPIRepoURL/releases | jq -r '.[0].tag_name' | sed 's/v//;s/-beta//')

ventoyCurrentVersion=$(<$ventoyROOT/ventoy/version)
if [ "$ventoyLatestRelease" != "$ventoyCurrentVersion" ];then
	Ventoy2DiskLatestGitHubReleaseURL=$(\curl -Ls $protocol://$gitHubAPIRepoURL/releases |  jq -r '.[0].assets[] | select( .content_type | match( "application/.*gzip" ) ).browser_download_url')
	if [ -n "$Ventoy2DiskLatestGitHubReleaseURL" ];then
		echo "=> Ventoy2DiskLatestGitHubReleaseURL = <$Ventoy2DiskLatestGitHubReleaseURL>"
		\curl -Ls "$Ventoy2DiskLatestGitHubReleaseURL" | tar -C /tmp -xz || exit
		rsync="$(which rsync) -uth -P -z --skip-compress=$RSYNC_SKIP_COMPRESS_LIST"
		cp2ext234="$rsync -ogpuv -lSH"
		test -d $ventoyROOT/ || sudo mkdir -pv $ventoyROOT/
		time sudo $cp2ext234 -r /tmp/ventoy-$ventoyLatestRelease/* /opt/ventoy
		sudo chown root -R $ventoyROOT/*
		rm -fr /tmp/ventoy-$ventoyLatestRelease/
		test -f $ventoyROOT/tool/x86_64/ash && sudo rm -v $ventoyROOT/tool/x86_64/ash

		if cd $ventoyROOT && [ $# != 0 ];then
			sudo ./Ventoy2Disk.sh -l "$@"
			tac $ventoyROOT/log.txt | sed "/^#* Ventoy2Disk/q" | tac
		fi
	fi
fi
