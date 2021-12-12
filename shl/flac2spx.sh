#!/usr/bin/env bash

set -o nounset
set -o errexit

function flac2spx() 
{ 
	ffmpeg="command ffmpeg -hide_banner -probesize 400M -analyzeduration 400M"
    typeset inputFile="$1"
    if [ -s "$inputFile" ]; then
        outputFile=${inputFile/.flac/_speex.oga}
        echo "==> outputFile = $outputFile"
        if [ ! -s "$outputFile" ]; then
            namedPipe=$(mktemp -u).wav
            mkfifo $namedPipe
            time $ffmpeg -i "$inputFile" -ar 16k $namedPipe -y & time speexenc -V --quality 10 --vbr $namedPipe "$outputFile"
            \rm $namedPipe
            sync
            touch -r "$inputFile" "$outputFile"
        else
            echo "=> ERROR: The file <$outputFile> already exits." 1>&2
            return 1
        fi
        echo "=> outputFile = <$outputFile>"
    else
        echo "=> ERROR: The file <$inputFile> does not exit or is empty." 1>&2
    fi
}

function init() {
	export LC_TIME=fr_FR.UTF-8
	logDir=$HOME/log
	export logFile=$logDir/flac2spx_$(date +%Y%m%d_%HH).log
	mkdir -pv $logDir
}

function main() {
	ffprobe="command ffprobe -hide_banner -probesize 400M -analyzeduration 400M"
	echo "=> Current time :"
	date +"%x %X"
	echo "=> Crontab environment :"
	env | sort
	echo
	df -PTh .
	echo
	time for file in $(\ls *.flac)
	do
		flac2spx $file 
		$ffprobe ${file/.flac/_speex.oga} && \rm -v $file && sync
	done 2>&1
	echo "=> logFile = <$logFile>"
	echo
	df -PTh .
}

init
main | tee -a $logFile
