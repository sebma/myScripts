#!/usr/bin/env sh

for module
do
		if ! python2 -c "import $module" 2>&1 | grep ImportError
		then
				printf "=> The module $module\tv%s is installed.\n" $(python2 -c "import $module;print $module.__version__ ")
		fi
done
