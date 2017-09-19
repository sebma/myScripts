#!/usr/bin/env bash

set -o nounset

if [ README.template -nt README.md ] || [ $0 -nt README.md ]
then
	cat README.template > README.md
	lastArg="$(eval echo \$$#)"
	if [ $# -ge 1 ] && [ -x "$lastArg" ]
	then
		echo "## Usage of \"$lastArg\" :" >> README.md
		echo "<pre><code>" >> README.md
		[ $# = 1 ] && args=./$1 || args=$(sed "s|\(.*\) |\1 ./|;" <<< $@) #On remplace le dernier " " par " ./"
		$args -h >> README.md 2>&1
		retCode=$?
		echo "</code></pre>" >> README.md
	fi

	cat <<-EOF >> README.md

[Parent directory](..)

## License

[GPLv3](https://www.gnu.org/licenses/gpl-3.0.html)  
[GPLv3 in MarkDown](LICENSE.md)
EOF
	test $? = 0 && echo "=> INFO : README.md has been successfully updated."
	git ls-files README.md | grep -qx README.md || git add README.md
	[ $retCode = 0 ] && git commit README.md -m "Updated README.md"
else
	echo "=> README.template is not newer than README.md : Nothing to do" >&2
	exit 3
fi
