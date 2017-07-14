#!/usr/bin/env bash

function gitClone@nonEmptyDir () 
{ 
	local url="$1"
	local dir="$2"
	test $dir || dir=.
	test $url && { 
		git init "$dir"
		git remote add origin "$url"
	}
}

gitClone@nonEmptyDir "$@"
