#!/usr/bin/env sh

test $# = 0 && {
	echo "=> Usage: $(basename $0) <wget args> URL" >&2
	exit 1
}

lastArg="$(eval echo \$$#)"
baseUrl="$(echo $lastArg | sed -r "s,(https?|s?ftp)://,," | cut -d/ -f1)"
#wget --output-file=$0-$(date +%Y%m%d-%H_%M_%S).log --no-verbose --no-parent --continue --timestamping --server-response --random-wait --no-directories --directory-prefix=$baseUrl/ --user-agent=Mozilla --content-disposition --convert-links --page-requisites --recursive --level=1 --reject index.html --accept $@
set -x
#wget --no-verbose --no-parent --continue --timestamping --server-response --random-wait --no-directories --directory-prefix=$baseUrl/ --user-agent=Mozilla --content-disposition --convert-links --page-requisites --recursive --level=1 --reject index.html --accept "$@"
#wget --no-parent --continue --timestamping --server-response --random-wait --no-directories --directory-prefix=$baseUrl/ --user-agent=Mozilla --content-disposition --convert-links --page-requisites --recursive --level=1 --reject index.html --accept "$@"
#wget --no-parent --continue --timestamping --random-wait --no-directories --directory-prefix=$baseUrl/ --user-agent=Mozilla --content-disposition --convert-links --page-requisites --recursive --level=1 --reject index.html --accept "$@"
wget --no-parent --continue --timestamping --random-wait --directory-prefix=$baseUrl/ --user-agent=Mozilla --content-disposition --convert-links --page-requisites --recursive --reject index.html --accept "$@"
