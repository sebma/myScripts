#!/usr/bin/env bash

getInterpreter() {
	local args=( "$@" )
	local interpreter=${args[-1]}
	echo "=> interpreter = $interpreter"
}

#getInterpreter "$@"
args=( "$@" )
firstArg=${@:0:1}
echo "=> interpreter = $firstArg"
