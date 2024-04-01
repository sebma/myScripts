#!/usr/bin/env bash

ytdlpUpdate ()
{
	if [ $# -gt 1 ]; then
		echo "=> Usage: $FUNCNAME [ytdlGitURL]"
		return 1
	else
		if [ $# = 1 ]; then
			local ytdlpGitURL=$1
		else
			local ytdlpGitURL=https://github.com/yt-dlp/yt-dlp
			local ytdlpPyPI_URL=https://pypi.org/pypi/yt-dlp
		fi
	fi
	local sudo=""
	test -z "$isAdmin" && isAdmin=$(groups 2>/dev/null | \egrep -wq "sudo|adm|admin|root|wheel" && echo true || echo false)
	if $isAdmin; then
		sudo="command sudo -H"
	fi
	local package=yt-dlp
	local yt_dlp="$(type -P $package)"
	if [ -n "$yt_dlp" ]; then
		local ytdlpCurrentRelease=$($package --version)
		echo "=> The current version of $package is <$ytdlpCurrentRelease>."
		echo "=> Searching for the latest release on $ytdlpPyPI_URL ..." 1>&2
		local ytdlpLatestRelease=$(\curl -qLs $ytdlpPyPI_URL/json | jq -r .info.version)
		if [ -z "$ytdlpLatestRelease" ]; then
			set -o pipefail
			echo "=> Couldn't find the latest release on $ytdlpPyPI_URL, checking the $ytdlpGitURL repository ..." 1>&2
			local ytdlpLatestRelease=$(\git ls-remote --tags --refs $ytdlpGitURL | awk -F/ '{print$NF}' | sort -rV | head -1)
			set +o pipefail
		else
			if echo $ytdlpLatestRelease | cut -d. -f4 | \grep . -q; then
				ytdlpLatestRelease=$(printf "%04d.%02d.%02d.%d" $(echo $ytdlpLatestRelease | cut -d. -f1-4 | tr . " "))
			else
				ytdlpLatestRelease=$(printf "%04d.%02d.%02d" $(echo $ytdlpLatestRelease | cut -d. -f1-3 | tr . " "))
			fi
			echo "=> Found the <$ytdlpLatestRelease> version." 1>&2
		fi
		if [ "$ytdlpLatestRelease" != $ytdlpCurrentRelease ]; then
			local ytdlPythonVersion=$($yt_dlp --ignore-config -v 2>&1 | awk -F "[ .]" '/Python version/{printf$4"."$5}')
			$sudo pip$ytdlPythonVersion install -U $package
			ytdlpTestURLs="https://youtu.be/vWYp2iGMDcM https://www.dailymotion.com/video/x5850if https://vimeo.com/groups/57545/videos/13262021 https://ok.ru/video/2091889462009"
			echo "=> Checking if $package can parse these URLs : $ytdlpTestURLs ..."
			if time ! yt-dlp -q -F $ytdlpTestURLs > /dev/null; then
				echo "=> At least one of them failed parsing so rolling back to $package version <$ytdlpCurrentRelease> ..."
				set -x
				$sudo pip$ytdlPythonVersion install $package==$ytdlpCurrentRelease
				set +x
			else
				echo "=> Success."
			fi
		else
			echo "=> [$FUNCNAME] INFO : You already have the latest release, which is $ytdlpLatestRelease." 1>&2
		fi
	else
		echo "=> [$FUNCNAME] INFO : $package is not installed, installing $package ..." 1>&2
		$sudo pip3 install -U $package
	fi
}

ytdlpUpdate "$@"
