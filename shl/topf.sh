#!/usr/bin/env bash

topf () { 
	local find="command find"
	local findExcludedPathList="/proc /sys /dev"
	local findPrunePathsExpression="( -type d -a ( -path .git/ $(printf -- " -o -path %s" $findExcludedPathList) ) ) -prune -o"
	local -i lines=10
	[ $# -ge 1 ] && local lines=$1 && shift

    $find "$@" -xdev $findPrunePathsExpression -type f -size +10M -exec ls -l --block-size=M --time-style=+"%Y-%m-%d %T" {} \; 2> /dev/null | sort -nrk5 | head -n $lines | numfmt --field 5 --from=iec --to=iec-i --suffix=B
}

topf "$@"
