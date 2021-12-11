#!/usr/bin/env bash

xpiInfo()
{ 
	local xpiFile
	for xpiFile
	do
		echo "=> xpiFile = $xpiFile"
		if unzip -t "$xpiFile" | \grep -wq install.rdf; then
			for field in em:id em:name em:version em:description em:homepageURL
			do
				unzip -q -p "$xpiFile" install.rdf | awk -F "<|>" /$field/'{if(!f)print$2"="$3;f=1}'
			done | column -ts '='
		else
			if unzip -t "$xpiFile" | \grep -wq manifest.json; then
				unzip -q -p "$xpiFile" manifest.json | jq '{name:.name , version:.version , description:.description , id:.applications.gecko.id, url:.homepage_url}'
			fi
		fi
		echo
	done
}

xpiInfo "$@"
