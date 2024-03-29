#!/usr/bin/env bash

set -o nounset

function initColors {
        typeset escapeChar=$'\e'
        normal="$escapeChar[m"
        bold="$escapeChar[1m"
        blink="$escapeChar[5m"
        blue="$escapeChar[34m"
        cyan="$escapeChar[36m"

        yellowOnRed="$escapeChar[33;41m"

        greenOnBlue="$escapeChar[32;44m"
        yellowOnBlue="$escapeChar[33;44m"
        cyanOnBlue="$escapeChar[36;44m"
        whiteOnBlue="$escapeChar[37;44m"

        redOnGrey="$escapeChar[31;47m"
        blueOnGrey="$escapeChar[34;47m"
}

initColors

if type xmlstarlet >/dev/null 2>&1
then
	xpathTool=xmlstarlet
	xpathCMD="command xmlstarlet select -t -v"
elif type xml >/dev/null 2>&1
then
	xpathTool=xml
	xpathCMD="command xml select -t -v"
elif type xpath >/dev/null 2>&1
then
	xpathTool=xpath
	xpathCMD="command xpath select -q -e"
fi

#echo "=> xpathTool = $xpathTool"

xpathExtensionIDQueryList="//Description[@about='urn:mozilla:install-manifest']/em:name/text() //Description[@about='urn:mozilla:install-manifest']/@em:name/text() //Description[@rdf:about='urn:mozilla:install-manifest']/em:name/text() //RDF:Description[@RDF:about='urn:mozilla:install-manifest']/@em:name"

for xpiFile
do
	echo
	echo "=> xpiFile = $xpiFile"
	installRDFFileName=/tmp/$(basename $xpiFile .xpi).install.rdf
	unzip -q -c -o "$xpiFile" install.rdf | sed "s/ xmlns=[^ ]*//" >$installRDFFileName #A cause des default namespace mal gere par xmlstarlet
	#printf "=> XML Validating of the file "
	xmlstarlet validate --err $installRDFFileName >/dev/null || {
		echo
		echo "$blink$yellowOnRed==> ERROR: This <$installRDFFileName> file in an invalid xml file, proceeding to the next firefox extension ...$normal" >&2
		echo
		continue
	}

	for xpathExtensionIDQuery in $xpathExtensionIDQueryList
	do
#		echo "=> xpathCMD = $xpathCMD"
		if [ $xpathTool = xmlstarlet ] || [ $xpathTool = xml ]
		then
	                xpathExtensionIDQuery="$xpathExtensionIDQuery -n"
		fi

		echo "=> xpathExtensionIDQuery = $xpathExtensionIDQuery"
		extensionName=$($xpathCMD $xpathExtensionIDQuery $installRDFFileName)
		test "$extensionName" && break
	done
	echo "$greenOnBlue==> extensionName = <$extensionName>$normal"
done
