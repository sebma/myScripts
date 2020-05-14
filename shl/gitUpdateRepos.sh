#/usr/bin/env sh

for dir
do
	if cd $dir;then
		git config remote.origin.url | awk '/github.com/{print"=> Updating from <"$NF"> ..."}'
		git pull && sync
		cd - >/dev/null
	fi
done
