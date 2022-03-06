#!/usr/bin/env zsh

get_interpreter() {
	interpreter=$(ps -o args= $$ | awk '{print sub("^/.*/","");print}')
	echo $interpreter  
}

interpreter=$(get_interpreter)
echo "=> interpreter = <$interpreter>"
