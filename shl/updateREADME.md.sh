#!/usr/bin/env bash

set -o nounset

if [ README.template -nt README.md ] || [ $0 -nt README.md ]
then
	cat README.template > README.md
	if [ $# = 1 ] && [ -x "$1" ]
	then
		echo "## Usage of \"$1\" :" >> README.md
		./"$1" --mdh | sed "1s/^.*<pre>/<pre>/" >> README.md
	fi

	cat <<-EOF >> README.md

[Parent directory](..)

## License

[GPLv3](https://www.gnu.org/licenses/gpl-3.0.html)  
[GPLv3 in MarkDown](LICENSE.md)
EOF
	test $? = 0 && echo "=> INFO : README.md has been successfully updated."
	git ls-files README.md | grep -qx README.md || git add README.md
	git commit README.md -m "Updated README.md"
else
	echo "=> README.template is not newer than README.md : Nothing to do" >&2
	exit 3
fi
