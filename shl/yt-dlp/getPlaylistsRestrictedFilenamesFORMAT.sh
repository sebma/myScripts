#!/usr/bin/env bash

function getPlaylistsRestrictedFilenamesFORMAT () {
	trap 'rc=130;set +x;echo "=> $FUNCNAME: CTRL+C Interruption trapped.">&2;return $rc' INT
	local playList playListTitle="not_yet_known" listOfUrls="not_yet_known" fqdn="not_yet_known" service="not_yet_known"
	local format=unset
	test $# -gt 1 && format=$1 && shift
	for playList
	do
		echo "=> Treating playList : $playList ..." 1>&2
		playListTitle=$(yt-dlp --ignore-config --ignore-errors --flat-playlist -J $playList | jq -r '.title')
		playListTitle="$(echo $playListTitle | sed -E "s/ /_/g;s/'/_/g;s/\|/-/g;s/[éè]/e/g" | tr -d "[:]")"
		mkdir -pv $playListTitle && cd $playListTitle
		if echo $playList | \egrep -q "dailymotion|vevo|tonvid"; then
			listOfUrls=$(\curl -Ls "$playList" | hxwls 2> /dev/null | awk -F '&' '/\<(watch|video)\>/{print$1}' | sort -u | paste -sd" ")
			test $? != 0 && return
		else
			fqdn=$(echo "$playList" | sed "s|https\?://||" | cut -d/ -f1)
			service=$(echo $fqdn | awk -F. '{print$(NF-1)}')
			listOfUrls=$(time ytdlpGetVideoURLsFromPlayListURL.sh $playList)
		fi
		getRestrictedFilenamesFORMAT.sh -i -f $format $listOfUrls
		cd - > /dev/null
	done
	trap - INT
}

function getPlaylistsRestrictedFilenamesSD() {
	local height=360
	local other_Formats=low/sd/std/${height}p
	local possibleFormats="18/best[vcodec^=avc1][height<=?$height]/bestvideo[vcodec^=avc1][height<=?$height]+bestaudio[ext=m4a]/$other_Formats"
	getPlaylistsRestrictedFilenamesFORMAT -f "($possibleFormats/$bestFormats)" $@ # because of the "eval" statement in the "youtube_dl" bash variable
}

function main() {
	if locale | grep -i C.UTF-8 -q;then
		declare -gx LANG=C.UTF-8
	else
		declare -gx LANG=C
	fi

	declare -gx scriptBaseName=${0/*\//}
	declare -gx scriptExtension=${0/*./}
	declare -gx funcName=${scriptBaseName/.$scriptExtension/}

	time $funcName $@
	return $?
}

main $@

