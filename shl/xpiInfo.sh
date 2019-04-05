#!/usr/bin/env sh

xpiInfo()
{ 
	for xpiFile
	do
		echo "=> xpiFile = $xpiFile"
		if unzip -q -l $xpiFile | \grep -q install.rdf
		then
			printf "em:id = "
			unzip -q -p $xpiFile install.rdf | egrep --color=auto -m1 "em:id" | awk -F "<|>" '{print$3}'
			printf "em:name = "
			unzip -q -p $xpiFile install.rdf | egrep --color=auto -m1 "em:name" | awk -F "<|>" '{print$3}'
			printf "em:version = "
			unzip -q -p $xpiFile install.rdf | egrep --color=auto -m1 "em:version" | awk -F "<|>" '{print$3}'
		elif unzip -q -l $xpiFile | \grep -q manifest.json
		then
			printf "name = "
			unzip -q -p $xpiFile manifest.json | jq .name
			printf "version = "
			unzip -q -p $xpiFile manifest.json | jq .version
		fi
		echo
	done
}

xpiInfo $@
