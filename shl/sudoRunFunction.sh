#!/usr/bin/env bash

#sudoRunFunction() {
#	functionName="$1"
#	declare -F $functionName >/dev/null && sudo bash -xc "$(declare -f $functionName);$@"
	declare -F $1 >/dev/null && \sudo \bash -xc "$(declare -f $1);$@"
#}

#sudoRunFunction "$@"
