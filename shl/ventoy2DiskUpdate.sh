#!/usr/bin/env bash

scriptDir=$(dirname $0)
scriptDir=$(cd $scriptDir;pwd)
scriptBaseName=${0##*/}

app=ventoy
ventoyROOT=/opt/$app
Ventoy2DiskScript=$ventoyROOT/Ventoy2Disk.sh
protocol=https
gitHubURL=github.com
gitHubAPIURL=api.$gitHubURL
gitHubUser=ventoy
gitHubRepo=Ventoy
gitHubAPIRepoURL=$gitHubAPIURL/repos/$gitHubUser/$gitHubRepo

echo "=> Searching for the latest release on $protocol://$gitHubURL/$gitHubUser/$gitHubRepo ..."
ventoyLatestRelease=$(\curl -Ls $protocol://$gitHubAPIRepoURL/releases | jq -r '.[0].tag_name' | sed 's/v//;s/-beta//')
echo "=> Found the $ventoyLatestRelease version."
ventoyCurrentVersion=$(cat $ventoyROOT/ventoy/version 2>/dev/null)

if [ "$ventoyLatestRelease" = "$ventoyCurrentVersion" ];then
	echo "=> [$scriptBaseName] INFO : You already have the latest release, which is $ventoyLatestRelease."
else
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
