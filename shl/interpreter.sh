#!/usr/bin/env sh

get_interpreter() {
	interpreter=$(readlink /proc/$$/exe)
	interpreter=$(basename $interpreter)
	echo $interpreter
}

interpreter=$(get_interpreter)
echo "=> interpreter = <$interpreter>"
