#!/usr/bin/env bash

scriptDir=$(dirname $0)
scriptDir=$(cd $scriptDir;pwd)
#echo "=> scriptDir = <$scriptDir>"
$scriptDir/moveAudio2BlueToothSink.sh connected
