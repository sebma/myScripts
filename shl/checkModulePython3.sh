#!/usr/bin/env bash

for module
do
		if ! python3 -c "import $module" 2>&1 | grep ModuleNotFoundError
		then
				printf "=> The module $module\tv%s is installed.\n" $(python3 -c "import $module;print($module.__version__)")
		fi
done
