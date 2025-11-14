#!/usr/bin/env bash

model=""
if [ $# == 0 ];then
	model=$(lscpu | awk '/Model name/{for(i=3;i<=NF;i++) printf $i " "; print ""}')
elif [ $# == 1 ];then
	model=$1
else
	echo "=> Usage : $scriptName [cpu model]"
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
