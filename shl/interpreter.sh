#!/usr/bin/env zsh

get_interpreter() {
	interpreter=$(ps -o args= $$ | awk '{gsub("^/.*/","",$1);print $1}')
	echo $interpreter  
}

interpreter=$(get_interpreter)
echo "=> interpreter = <$interpreter>"
