#!/usr/bin/env bash

set -o nounset
set -o errexit

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

function initScript {
	chmod u+x $0 || sudo chmod u+x $0
	LANG=C
	interpreter=`ps -o pid,comm | awk /$$/'{print $2}'`
	test $interpreter != bash && test $interpreter != bashdb && {
		echo "$yellowOnRed=> Mauvais interpreteur (interpreter = $interpreter), veuillez relancer le script $(basename $0) de la maniere suivante: ./$0$normal" >&2
		return 127
	}

	[ $BASH_VERSINFO != 4 ] && {
		echo "$blink$yellowOnRed=> ERROR: Bash version >= 4 is needed for hash value tables.$normal" >&2
		return 1
	}

	thunderbirdVersion=$(thunderbird -V 2>/dev/null | awk '{print$NF}' | tr -d [A-Za-z] | awk -F. '{print $1"."$2$3$4}')
	test $thunderbirdVersion || {
		echo "$blink$yellowOnRed=> ERROR: Thunderbird is not installed.$normal" >&2
		return 2
	}
	local maxThunderbirdVersionSupported=-1

	local isLinux=$(uname -s | grep -q Linux && echo true || echo false)
	local distribName=""
	if $isLinux
	then
		distribName=$(\ls -1 /etc/*release /etc/*version 2>/dev/null | awk -F"/|-|_" '!/system/ && NR==1 {print$3}')
		test $distribName = debian && distribName=$(awk -F= '/DISTRIB_ID/{print tolower($2)}' /etc/lsb-release)
	else
	  distribName=Unix
  fi
	echo "=> distribName = $distribName"

	#set +o errexit
	local isAdmin=$(sudo -v && echo true || echo false)
	if $isAdmin
	then
		echo "=> Elevation de privileges reussie."
		echo "=> Les extensions seront installes pour tous les utilisateurs de la machine <$(hostname)>."
		sudo_cmd=sudo
	else
		echo "$yellowOnRed=> Echec d'elevation de privileges.$normal" >&2
		echo "=> Les extensions seront installes uniquement pour l'utilisateur <$USER> uniquement." >&2
		sudo_cmd=""
	fi
	echo

	local profileName=default
	if $isAdmin
	then
	  case $distribName in
			centos|redhat|ubuntu)
				test -d /usr/lib/thunderbird/extensions && extensionDir=/usr/lib/thunderbird/extensions || extensionDir=$(awk -F= '/LIBDIR=\//{print$2}' $(which thunderbird))/extensions
				test -d $extensionDir || extensionDir=/usr/lib/thunderbird-addons/extensions
				;;
			debian) extensionDir=/usr/lib/icedove/extensions ;;
			*) echo "$yellowOnRed=> <$distribName> is not supported by this script for the time being.$normal" >&2; return 3;;
		esac
	else
		profileName=$(awk -F= '/Profile0/{found=1} /Profile[^0]/{found=0} /Path=/ && found==1 {print$2}' $HOME/.thunderbird/profiles.ini)
		extensionDir=$HOME/.thunderbird/$profileName/extensions
	fi

	echo "=> extensionDir = $extensionDir"
	echo

	xpathCMD=""
	xpathTool=$(basename $(which xmlstarlet xml xpath xmllint 2>/dev/null | head -1))
	case $xpathTool in
		xmlstarlet|xml) xpathToolArgs="select -t -v";;
		xpath)			xpathToolArgs="-q -e";;
		xmllint)		xpathToolArgs="--xpath";;
		*) echo "$blink$yellowOnRed=> ERROR: No <xmlstarlet> nor <xpath> tool is installed.$normal" >&2;;
	esac
	test $xpathTool && xpathCMD="$xpathTool $xpathToolArgs"

	test "$xpathCMD" || {
		test $distribName = ubuntu && {
			echo "==> Installing <xmlstarlet> ..."
			sudo apt-get install xmlstarlet -qq -V
			echo "$yellowOnRed=> WARNING: Please re-run the script $(basename $0) to re-define the variables.$normal" >&2
		}
		return 4
	}

	fireFoxExtensionID={ec8030f7-c20a-464f-9b0e-13a3a9e97384}
	xpathExtensionIDQueryList="//Description[@about='urn:mozilla:install-manifest']/em:id/text() //Description[@about='urn:mozilla:install-manifest']/@em:id/text() //Description[@rdf:about='urn:mozilla:install-manifest']/em:id/text() //RDF:Description[@RDF:about='urn:mozilla:install-manifest']/@em:id"
}

function main {
	initColors
	initScript

	notInstalledPluginList=""
	typeset -A addonNumber
	addonNumber[adblock-edge]=394968
	addonNumber[adblock-plus]=1865
	addonNumber[british-english-dictionary-]=399288
	addonNumber[dictionary-switcher]=3414
	addonNumber[dictionnaires-francais]=354872
	addonNumber[fireshot]=5648
#	addonNumber[importexporttools]=310624
#	addonNumber[lightning]=2313/platform:2/
	addonNumber[open-with]=11097
	addonNumber[quick-locale-switcher]=1333
	addonNumber[restartless-restart]=249342
	addonNumber[text-complete]=2320
	addonNumber[toolbar-buttons]=2377

#	addonNumber[]=

	thunderbirdAddonBaseURL=https://addons.mozilla.org/thunderbird/downloads/latest

	typeset -i nb=0
#	echo $(echo "${!addonNumber[@]}" | tr ' ' '\n' | sort)


	argc=$#
	if [ $argc = 0 ]
	then
		addonList=$(echo "${!addonNumber[@]}"| tr ' ' '\n' | sort)
	else
		addonList=$@
	fi

#	for currentAddonName in $(echo "${!addonNumber[@]}"| tr ' ' '\n' | sort)
	for currentAddonName in $addonList
	do
		echo "=> currentAddonName = $currentAddonName"
		echo
		currentAddonFileName=$currentAddonName-latest.xpi
		xpiFile="$currentAddonFileName"
		echo "=> xpiFile = <$xpiFile>"

		currentAddonURL=$thunderbirdAddonBaseURL/${addonNumber[$currentAddonName]}
		set +e
		echo "=> currentAddonURL = $currentAddonURL"
		wgetMessage=$(wget --content-disposition -nv -cO"$currentAddonFileName" $currentAddonURL 2>&1)
		test $? = 0 || {
			echo "=> $blink$yellowOnRed$wgetMessage$normal." >&2
			rm $currentAddonFileName
			continue
			echo
		}
		set -e
		if test ! -f "$xpiFile"
		then
			echo $yellowOnRed
			echo "=> WARNING: <$xpiFile> not found.$normal" >&2
			echo
		 	continue
		fi

		installRDFFileName=$currentAddonName.install.rdf
		unzip -q -c -o "$xpiFile" install.rdf | sed "s/ xmlns=[^ ]*//" >$installRDFFileName #A cause des default namespace mal gere par xmlstarlet
		printf "=> XML Validating of the file "
		xmlstarlet validate --err $installRDFFileName || {
			echo $blink$yellowOnRed
			echo "=> ERROR: This <$installRDFFileName> file in an invalid xml file, proceeding to the next thunderbird extension ...$normal" >&2
			echo
			continue
		}

		for xpathExtensionIDQuery in $xpathExtensionIDQueryList
		do
			xpathMinThunderbirdVersionQuery="//Description[em:id=\"$fireFoxExtensionID\"]/em:minVersion/text()"
			xpathMaxThunderbirdVersionQuery="//Description[em:id=\"$fireFoxExtensionID\"]/em:maxVersion/text()"
	
			if [ $xpathTool = xmlstarlet ] || [ $xpathTool = xml ]
			then
				xpathExtensionIDQuery="$xpathExtensionIDQuery -n"
				xpathMinThunderbirdVersionQuery="$xpathMinThunderbirdVersionQuery -n"
				xpathMaxThunderbirdVersionQuery="$xpathMaxThunderbirdVersionQuery -n"
			fi
	
			echo "=> xpathExtensionIDQuery = $xpathExtensionIDQuery"
			extensionID=$($xpathCMD $xpathExtensionIDQuery $installRDFFileName)
			test $extensionID && break
		done

		echo "$greenOnBlue==> extensionID = <$extensionID>$normal"
		echo

		#Render <aardvark> extension compatible with thunderbird version currently installed
		toolbarButtonsExtensionID="{03B08592-E5B4-45ff-A0BE-C1D975458688}"
		if echo $extensionID | egrep -q "aardvark"
		then
			printf "=> Before, Thunderbird em:maxVersion = "
			$xpathCMD $xpathMaxThunderbirdVersionQuery $installRDFFileName
			xmlstarlet edit --inplace --update $xpathMaxThunderbirdVersionQuery -v 29.0 $installRDFFileName
			printf "=> After, Thunderbird em:maxVersion = "
			$xpathCMD $xpathMaxThunderbirdVersionQuery $installRDFFileName
			zip -q9f "$xpiFile" $installRDFFileName
		fi


		minThunderbirdVersionSupported=$($xpathCMD $xpathMinThunderbirdVersionQuery $installRDFFileName | tr -d "[A-Za-z]" | sed "s/*/9/" | awk -F. '{print $1"."$2$3$4}')
		maxThunderbirdVersionSupported=$($xpathCMD $xpathMaxThunderbirdVersionQuery $installRDFFileName | tr -d "[A-Za-z]" | sed "s/*/9/" | awk -F. '{print $1"."$2$3$4}')
#		echo "=> maxThunderbirdVersionSupported = $maxThunderbirdVersionSupported"

#		if $isAdmin
#		then
			if echo $thunderbirdVersion | grep -q "^3\."
			then
				if test -s $extensionDir/$extensionID/$installRDFFileName
				then
			 		echo "$greenOnBlue=> INFO: le plugin <$currentAddonName> est deja installe dans le repertoire <$extensionDir/$extensionID/>.$normal"
					let nb+=1
				else
					echo "=> Verification de la compatibilite du module <$currentAddonName> avec Thunderbird v$thunderbirdVersion ..."
#					if [ $(echo $thunderbirdVersion \< $minThunderbirdVersionSupported | bc -l) = 1 ] || [ $(echo $thunderbirdVersion \> $maxThunderbirdVersionSupported | bc -l) = 1 ]
					if [ $(echo $thunderbirdVersion \< $minThunderbirdVersionSupported | bc -l) = 1 ]
					then
						echo $blink$yellowOnRed
						echo "=> ERROR: Thunderbird v$thunderbirdVersion n'est pas supporte par le plugin <$currentAddonName> ($extensionID) qui supporte: $minThunderbirdVersionSupported < thunderbird < $maxThunderbirdVersionSupported.$normal" >&2
						notInstalledPluginList="$notInstalledPluginList $currentAddonName"
						echo
						continue
					fi

					echo "=> Installation du module <$currentAddonName> proprement dite dans <$extensionDir/> ..."
					let nb+=1
 					$sudo_cmd mkdir -vp "$extensionDir/$extensionID"
					$sudo_cmd unzip -vu "$xpiFile" -d "$extensionDir/$extensionID"
				fi
				$sudo_cmd rm "$xpiFile"
			else
#				echo "=> La version de Thunderbird est > 3"
				if test -s $extensionDir/$extensionID.xpi
				then
			 		echo "$greenOnBlue=> INFO: le plugin <$currentAddonName> est deja installe dans le fichier <$extensionDir/$extensionID.xpi>.$normal"
					let nb+=1
				else
					echo "=> Verification de la compatibilite du module <$currentAddonName> avec Thunderbird v$thunderbirdVersion ..."
#					if [ $(echo $thunderbirdVersion \< $minThunderbirdVersionSupported | bc -l) = 1 ] || [ $(echo $thunderbirdVersion \> $maxThunderbirdVersionSupported | bc -l) = 1 ]
					if [ $(echo $thunderbirdVersion \< $minThunderbirdVersionSupported | bc -l) = 1 ]
					then
						echo $blink$yellowOnRed
						echo "=> ERROR: Thunderbird v$thunderbirdVersion n'est pas supporte par le plugin <$currentAddonName> ($extensionID) qui supporte: $minThunderbirdVersionSupported < thunderbird < $maxThunderbirdVersionSupported.$normal" >&2
						notInstalledPluginList="$notInstalledPluginList $currentAddonName"
						echo
						continue
					fi

					echo "=> Installation du module <$currentAddonName> proprement dite dans <$extensionDir/> ..."
					let nb+=1
#			  		$sudo_cmd rsync -vpt "$xpiFile" $extensionDir/$extensionID.xpi
			  		$sudo_cmd cp -puv "$xpiFile" $extensionDir/$extensionID.xpi
					echo "=> DONE."
				fi
				$sudo_cmd rm "$xpiFile" $installRDFFileName
			fi
#			echo $extensionID | grep -q aardvark && rm "$xpiFile"
		echo
		echo "=> Suivant ..."
		echo
	done
	test "$notInstalledPluginList" && echo "$yellowOnRed=> WARNING: Les plugins suivants n'ont pas pu etre installes:$notInstalledPluginList.$normal" >&2
	echo "=> Le nombre total de plugins installe ou deja present est de $nb."
	echo "=> Termine."
	return 0
}

main $@
