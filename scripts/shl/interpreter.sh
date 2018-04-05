#!/usr/bin/env ksh

get_interpreter() {
	typeset scriptPID=$$
	typeset interpreter=`ps -o pid,args | awk "/$$/&&!/awk/"'{gsub("^/.*/","",$2);print $2}'`
	echo       $interpreter  
}

interpreter=`get_interpreter`
echo "=> interpreter = <$interpreter>"
