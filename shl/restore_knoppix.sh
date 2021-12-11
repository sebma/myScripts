#!/usr/bin/env bash
ShlDir=$(dirname $0)
sudo chown knoppix:knoppix $ShlDir/../knoppix.sh
cp -v -f $ShlDir/knoppix.back.sh $ShlDir/../knoppix.sh
sync
