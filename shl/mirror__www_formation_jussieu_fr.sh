#!/usr/bin/env bash


[ $# = 0 ] && {
	echo "=> Usage : $0 dir1 dir2 dir3 ..." 
	exit 1
} >&2

wget=$(which wget)
logDir=logs
mkdir -p $logDir

for dir in abd aoi ars cdp irt logs lpi
do
	time $wget --append-output=$logDir/${dir}_download.log --level 10 --no-host-directories --no-parent --continue --timestamping --random-wait --user-agent=Mozilla --content-disposition --convert-links --page-requisites --recursive http://www.formation.jussieu.fr/$dir/
done
