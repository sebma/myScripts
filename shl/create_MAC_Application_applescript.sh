#!/usr/bin/env bash

for bin
do
	cat <<-EOF | tee ${bin^}.applescript
on run
 do shell script "$(which $bin)"
end run
EOF
	echo "=> Here is the command to create ${bin^}.app :"
	echo osacompile -o /Application/${bin^}.app ${bin^}.applescript
#	rm -iv ${bin^}.applescript
done
