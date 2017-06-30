#!/usr/bin/env bash

echo "=> BASH_VERSION = $BASH_VERSION"
function testForLoopMac {
local file
for file
do
	echo File=$file
done | egrep "$file"
}

function videoInfoBis {
local file
for file
do
	echo File=$file
done | egrep "$file|k"
}

testForLoopMac $@

videoInfoBis $@
