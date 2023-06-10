#!/usr/bin/env bash

topflines () { 
	local find="command find"
	local findExcludedPathList="./proc ./sys ./dev"
	local findPrunePathsExpression="( -type d -a ( -name .git $(printf -- " -o -path %s" $findExcludedPathList) ) ) -prune -o"

	$find "$@" -xdev $findPrunePathsExpression -type f -size +10M -exec ls -l --block-size=M --time-style=+"%Y-%m-%d %T" {} \; 2> /dev/null | sort -nrk5 | head -n $(($LINES-4)) | numfmt --field 5 --from=iec --to=iec-i --suffix=B
}

topflines "$@"
