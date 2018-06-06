#!/usr/bin/env bash

set -o nounset
#LICENSE="[GPLv3](https://www.gnu.org/licenses/gpl-3.0.html)"
LICENSE=""

if [ $# -ge 1 ] && [ $1 = "-h" ]
then
	echo "=> Usage : $(basename $0) [scriptName/binName]" >&2
	exit -1
fi

if [ README-template.md -nt README.md ] || [ $0 -nt README.md ]
then
	cat README-template.md > README.tmp.md
	lastArg="$(eval echo \$$#)"
	if [ $# -ge 1 ] && [ -x "$lastArg" ]
	then
		echo "## Usage of \"$lastArg\" :" >> README.tmp.md
		echo "<pre><code>" >> README.tmp.md
		[ $# = 1 ] && args=./$1 || args=$(sed "s|\(.*\) |\1 ./|;" <<< $@) #On remplace le dernier " " par " ./"
		$args -h >> README.tmp.md 2>&1
		retCode=$?
		echo "</code></pre>" >> README.tmp.md
	fi

	cat <<-EOF >> README.tmp.md

[Parent directory](..)

## License

EOF
	test -f LICENSE.md && cat <<-EOF >> README.tmp.md
[LICENSE in MarkDown](LICENSE.md)
EOF
	gfmtoc -n README.tmp.md > README.md
	cat README.tmp.md >> README.md
	\rm README.tmp.md
	test $? = 0 && echo "=> INFO : README.md has been successfully updated."
	git ls-files README.md | grep -qx README.md || git add README.md
	retCode=$?
	[ $retCode = 0 ] && git commit README.md -m "Updated README.md"
else
	echo "=> README-template.md is not newer than README.md : Nothing to do" >&2
	exit 3
fi
