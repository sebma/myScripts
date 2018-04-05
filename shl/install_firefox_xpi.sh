#!/bin/sh -eu
 
test $# -eq 0 && {
  echo "=> Usage: $0 <xpiFileName1> [<xpiFileName2>] [...]" >&2
  exit 1
}
 
firefoxVersion=$(firefox -V | awk '{print$NF}')
#xpiFile=$1
for xpiFile
do
	rm -f install.rdf
	echo
	echo "=> xpiFile = <$xpiFile>"
	if test ! -f "$xpiFile" 
	then	
	       	echo "ERROR: => <$xpiFile> not found." >&2 
	       	exit 2 
	fi
	
	unzip -q "$xpiFile" install.rdf
	extensionID=$(sed "s/RDF://g" install.rdf | xpath -q -e "//Description[@about='urn:mozilla:install-manifest']/em:id/text()")
	test $extensionID || {
		echo "INFO : => extensionID not found in <$xpiFile>, trying another method ..."
		extensionID=$(sed "s/RDF://g" install.rdf | xpath -q -e "//Description[@about='urn:mozilla:install-manifest']/@em:id" | awk -F'"' '{print$2}')
		test $extensionID || {
			echo "ERROR: => extensionID could not be found in <$xpiFile>." >&2
			continue
		}
	}

	echo "=> extensionID = <$extensionID>"
	 
	test $(id -u) = 0 && extensionDir=/usr/lib/firefox-$firefoxVersion/extensions || extensionDir=$HOME/.mozilla/firefox/default/extensions
	echo "=> extensionDir = $extensionDir"
	 
	echo $firefoxVersion | grep -q "^3\." && {
		mkdir -vp "$extensionDir/$extensionID"
		unzip -u "$xpiFile" -d "$extensionDir/$extensionID"
	}
#   	} || cp -vp "$xpiFile" $extensionDir/$extensionID.xpi
	zipgrep em:unpack "<$xpiFile>" install.rdf
done
