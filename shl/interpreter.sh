#!/usr/bin/env zsh

get_interpreter() {
	if which ps >/dev/null 2>&1;then
 		interpreter=$(ps -o args= $$ | awk '{print sub("^/.*/","");print}')
   	else
    		interpreter=$(readlink -e /proc/$$/exe)
		interpreter=$(basename $interpreter)
    	fi
	echo $interpreter  
}

interpreter=$(get_interpreter)
echo "=> interpreter = <$interpreter>"
