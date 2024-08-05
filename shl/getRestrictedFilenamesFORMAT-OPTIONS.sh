#!/usr/bin/env bash

osType=$(uname -s)
if [ $osType = Linux ];then
	#getopt=$(getopt -V | grep getopt.*enhanced -q && getopt || getopts)
	if ! getopt -V | grep getopt.*util-linux -q && getopt=getopt;then
		echo "=> ERROR : You must use getopt from util-linux." >&2
		exit 2
	fi
elif [ $osType = Darwin ];then
	getopt=/usr/local/opt/gnu-getopt/bin/getopt
fi
