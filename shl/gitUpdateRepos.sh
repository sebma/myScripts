#/usr/bin/env bash

gitUpdateRepos () {
	local remoteRepoUrl=""
	local dir=""

	if ! type -P git >/dev/null;then
		echo "=> $FUNCNAME: ERROR : You must first install git." >&2
		return 1
	fi

	for dir
	do
		if cd $dir;then
			remoteRepoUrl=$(git config --local remote.origin.url)
			test -n "$remoteRepoUrl" && echo "=> Updating <$dir> repo. from <$remoteRepoUrl> repo. ..." 1>&2 && git pull && sync
			cd - >/dev/null
		fi
	done
	unset dir
}

gitUpdateRepos "$@"
