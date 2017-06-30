#!/usr/bin/env ksh

for file
do
	dir=$(dirname "$file")
	cd $dir
	ext=$(basename "$file" | cut -d. -f2-)
	url=$(basename "$file" .$ext | awk -F"__" '{print$NF}')
	echo "=> getRestrictedFilenamesSD.sh $url ..."
	getRestrictedFilenamesSD.sh $url
	cd - >/dev/null
done
