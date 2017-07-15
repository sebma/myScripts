#!/usr/bin/env bash

function gitClone@nonEmptyDir () 
{ 
	local url="$1"
	local dir="$2"
	test $dir || dir=.
	test $url && { 
		git init "$dir"
		git remote add origin "$url"
		git fetch
		#git pull origin master
		#git branch --set-upstream-to=origin/master master
	}
}

gitClone@nonEmptyDir "$@"
