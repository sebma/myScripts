#!/usr/bin/env bash

topf () { 
	local find=$(which find)
	local findExcludedPathList="./proc ./sys ./dev"
	local findPrunePathsExpression="( -type d -a ( -name .git $(printf -- " -o -path %s" $findExcludedPathList) ) ) -prune -o"
	[ $# = 0 ] && local lines=10 || local lines=$1

    $find . -xdev $findPrunePathsExpression -type f -size +10M -exec ls -l --block-size=M --time-style=+"%Y-%m-%d %T" {} \; 2> /dev/null | sort -nrk5 | head -n $lines | numfmt --field 5 --from=iec --to=iec-i --suffix=B | column -t
}

topf "$@"
