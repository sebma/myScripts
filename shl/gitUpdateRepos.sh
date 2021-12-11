#/usr/bin/env bash

gitUpdateRepos () {
	local remoteRepoUrl=""
	local dir=""
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
