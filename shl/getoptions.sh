#!/usr/bin/env bash

set -o nounset

scriptName=$(basename $0)
function scriptHelp {
	cat <<-EOF >&2
Usage: $scriptName [STRING]...
  or:  $scriptName OPTION
Repeatedly output a line with all specified STRING(s), or 'y'.

      -h	display this help and exit
      -v	output version information and exit
EOF
	exit 1
}

function initArgs {
	local OPTSTRING=23h

	while getopts $OPTSTRING NAME; do
		case "$NAME" in
		2|3) minicondaVersion=$NAME ;;
		h|*) scriptHelp ;;
		esac
	done
	[ $OPTIND = 1 ] && scriptHelp
	shift $((OPTIND-1)) #non-option arguments
	arg=$1
}

initArgs $@
