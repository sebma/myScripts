#!/usr/bin/env zsh

get_interpreter() {
	interpreter=$(ps -o args= $$ | awk '{print gensub("^/.*/","",1,$1)}')
	echo $interpreter  
}

interpreter=$(get_interpreter)
echo "=> interpreter = <$interpreter>"
