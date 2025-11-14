#!/usr/bin/env bash

model=""
scriptBaseName=${0/*\//}
if [ $# == 0 ];then
	model=$(awk '/model.name/{for(i=4;i<=NF;i++) printf $i " "; print "";exit}' /proc/cpuinfo)
elif [ $# == 1 ];then
	model=$1
else
    echo "=> Usage : $scriptBaseName [cpu model]" >&2
	exit 1
fi

echo "CPU Model: $model"

if [[ $model =~ i[0-9]+-([0-9]) ]]; then
	generation=${BASH_REMATCH[1]}
	echo "Intel Generation: $generation"
elif [[ $model =~ Ryzen\ ([0-9]+) ]]; then
	generation=${BASH_REMATCH[1]}
	echo "AMD Ryzen Generation: ${generation:0:1} (e.g., Ryzen 5 5600X is from the 5th generation)"
else
	echo "Unknown CPU model format."
fi
