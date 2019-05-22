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

	palemoonVersion=$(palemoon -V 2>/dev/null | awk '{print$NF}' | tr -d [A-Za-z] | awk -F. '{print $1"."$2$3$4}')
	test $palemoonVersion || {
		echo "$blink$yellowOnRed=> ERROR: Palemoon is not installed.$normal" >&2
		return 2
	}
	local maxPalemoonVersionSupported=-1

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
				test -d /usr/lib/palemoon/browser/extensions && extensionDir=/usr/lib/palemoon/browser/extensions
				test -d $extensionDir || extensionDir=/opt/palemoon/browser/extensions
				;;
			debian) extensionDir=/usr/lib/iceweasel/extensions ;;
			*) echo "$yellowOnRed=> <$distribName> is not supported by this script for the time being.$normal" >&2; return 3;;
		esac
	else
		profileName=$(awk -F= '/Profile0/{found=1} /Profile[^0]/{found=0} /Path=/ && found==1 {print$2}' "$HOME/.moonchild productions/pale moon/profiles.ini")
		extensionDir="$HOME/.moonchild productions/pale moon/$profileName/extensions"
	fi

	echo "=> extensionDir = $extensionDir"
	echo

	xpathCMD=""
	if type xmlstarlet >/dev/null 2>&1
	then
		xpathTool=xmlstarlet
		xpathCMD="$(which xmlstarlet) select -t -v"
	elif type xml >/dev/null 2>&1
	then
		xpathTool=xml
		xpathCMD="$(which xml) select -t -v"
	elif type xpath >/dev/null 2>&1
	then
		xpathTool=xpath
		xpathCMD="$(which xpath) select -q -e"
	fi

	test "$xpathCMD" || {
		echo "$blink$yellowOnRed=> ERROR: No <xmlstarlet> nor <xpath> tool is installed.$normal" >&2
		test $distribName = ubuntu && {
			echo "==> Installing <xmlstarlet> ..."
			sudo apt-get install xmlstarlet -qq -V
			echo "$yellowOnRed=> WARNING: Please re-run the script $(basename $0) to re-define the variables.$normal" >&2
		}
		return 4
	}

	paleMoonExtensionID={ec8030f7-c20a-464f-9b0e-13a3a9e97384}
	xpathExtensionIDQueryList="//Description[@about='urn:mozilla:install-manifest']/em:id/text() //Description[@about='urn:mozilla:install-manifest']/@em:id/text() //Description[@rdf:about='urn:mozilla:install-manifest']/em:id/text() //RDF:Description[@RDF:about='urn:mozilla:install-manifest']/@em:id"
}

function main {
	initColors
	initScript

	notInstalledPluginList=""
	typeset -A addonNumber
	addonNumber[adblock-edge]=394968
	addonNumber[adblock-plus]=1865
	addonNumber[adblock-plus-pop-up-addon]=83098
	addonNumber[autoauth]=4949
	addonNumber[british-english-dictionary-]=399288
	addonNumber[dictionnaires-francais]=354872
	addonNumber[fireshot]=5648
	addonNumber[greasemonkey]=748
	addonNumber[hack-the-web]=333792
	addonNumber[html5-video-everywhere]=577606
	addonNumber[language-pack-install-helpe]=383991 #Surtout pour windows
	addonNumber[live-http-headers]=3829
	addonNumber[new-tab-tools]=376953
	addonNumber[open-with]=11097
	addonNumber[quick-locale-switcher]=1333
	addonNumber[session-manager]=2324
	addonNumber[toolbar-buttons]=2377
	addonNumber[user-agent-switcher]=59
	addonNumber[video-downloadhelper]=3006
#	addonNumber[watch-with-mpv]=301698
#	addonNumber[yahoomailhideadpanel]=466928
	addonNumber[webmail-ad-blocker]=7560

	addonNumber[builtwith]=8013
	addonNumber[translate-this]=323615
	addonNumber[wapplyser]=10229
	addonNumber[stylish]=2108
	addonNumber[vlc-youtube-shortcut]=475080/platform:2/
#	addonNumber[]=

	palemoonAddonBaseURL=http://addons.palemoon.org/addon/

	typeset -i nb=0
#	echo $(echo "${!addonNumber[@]}" | tr ' ' '\n' | sort)

	argc=$#
	if [ $argc = 0 ]
	then
		addonList=$(echo "${!addonNumber[@]}"| tr ' ' '\n' | sort)
	else
		addonList=$@
	fi

#	for currentAddonName in builtwith
#	for currentAddonName in $(echo "${!addonNumber[@]}"| tr ' ' '\n' | sort)
	for currentAddonName in $addonList
	do
		echo "=> currentAddonName = $currentAddonName"
		echo
		currentAddonFileName=$currentAddonName-latest.xpi
		xpiFile="$currentAddonFileName"
		echo "=> xpiFile = <$xpiFile>"

		currentAddonURL=$palemoonAddonBaseURL/${addonNumber[$currentAddonName]}
		set +e
		wgetMessage=$(wget --content-disposition -nv -cO"$currentAddonFileName" $currentAddonURL 2>&1)
		test $? = 0 || {
			echo "=> $blink$yellowOnRed$wgetMessage$normal." >&2
			#rm $currentAddonFileName
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
			echo "=> ERROR: This <$installRDFFileName> file in an invalid xml file, proceeding to the next palemoon extension ...$normal" >&2
			echo
			continue
		}

		for xpathExtensionIDQuery in $xpathExtensionIDQueryList
		do
			xpathMinPalemoonVersionQuery="//Description[em:id=\"$paleMoonExtensionID\"]/em:minVersion/text()"
			xpathMaxPalemoonVersionQuery="//Description[em:id=\"$paleMoonExtensionID\"]/em:maxVersion/text()"
	
			if [ $xpathTool = xmlstarlet ] || [ $xpathTool = xml ]
			then
				xpathExtensionIDQuery="$xpathExtensionIDQuery -n"
				xpathMinPalemoonVersionQuery="$xpathMinPalemoonVersionQuery -n"
				xpathMaxPalemoonVersionQuery="$xpathMaxPalemoonVersionQuery -n"
			fi
	
			echo "=> xpathExtensionIDQuery = $xpathExtensionIDQuery"
			extensionID=$($xpathCMD $xpathExtensionIDQuery $installRDFFileName)
			test $extensionID && break
		done

		echo "$greenOnBlue==> extensionID = <$extensionID>$normal"
		echo

		#Render <aardvark> extension compatible with palemoon version currently installed
		toolbarButtonsExtensionID="{03B08592-E5B4-45ff-A0BE-C1D975458688}"
		if echo $extensionID | egrep -q "aardvark"
		then
			printf "=> Before, Palemoon em:maxVersion = "
			$xpathCMD $xpathMaxPalemoonVersionQuery $installRDFFileName
			xmlstarlet edit --inplace --update $xpathMaxPalemoonVersionQuery -v 29.0 $installRDFFileName
			printf "=> After, Palemoon em:maxVersion = "
			$xpathCMD $xpathMaxPalemoonVersionQuery $installRDFFileName
			zip -q9f "$xpiFile" $installRDFFileName
		fi


		minPalemoonVersionSupported=$($xpathCMD $xpathMinPalemoonVersionQuery $installRDFFileName | tr -d "[A-Za-z]" | sed "s/*/9/" | awk -F. '{print $1"."$2$3$4}')
		maxPalemoonVersionSupported=$($xpathCMD $xpathMaxPalemoonVersionQuery $installRDFFileName | tr -d "[A-Za-z]" | sed "s/*/9/" | awk -F. '{print $1"."$2$3$4}')
#		echo "=> maxPalemoonVersionSupported = $maxPalemoonVersionSupported"

#		if $isAdmin
#		then
			if echo $palemoonVersion | grep -q "^3\."
			then
				if test -s $extensionDir/$extensionID/$installRDFFileName
				then
			 		echo "$greenOnBlue=> INFO: le plugin <$currentAddonName> est deja installe dans le repertoire <$extensionDir/$extensionID/>.$normal"
					let nb+=1
				else
					echo "=> Verification de la compatibilite du module <$currentAddonName> avec Palemoon v$palemoonVersion ..."
#					if [ $(echo $palemoonVersion \< $minPalemoonVersionSupported | bc -l) = 1 ] || [ $(echo $palemoonVersion \> $maxPalemoonVersionSupported | bc -l) = 1 ]
					if [ $(echo $palemoonVersion \< $minPalemoonVersionSupported | bc -l) = 1 ]
					then
						echo $blink$yellowOnRed
						echo "=> ERROR: Palemoon v$palemoonVersion n'est pas supporte par le plugin <$currentAddonName> ($extensionID) qui supporte: $minPalemoonVersionSupported < palemoon > $maxPalemoonVersionSupported.$normal" >&2
						notInstalledPluginList="$notInstalledPluginList $currentAddonName"
						echo
						continue
					fi

					echo "=> Installation du module <$currentAddonName> proprement dite dans <$extensionDir/> ..."
					let nb+=1
 					$sudo_cmd mkdir -vp "$extensionDir/$extensionID"
					$sudo_cmd unzip -vu "$xpiFile" -d "$extensionDir/$extensionID"
				fi
#				$sudo_cmd rm "$xpiFile"
			else
#				echo "=> La version de Palemoon est > 3"
				if test -s $extensionDir/$extensionID.xpi
				then
			 		echo "$greenOnBlue=> INFO: le plugin <$currentAddonName> est deja installe dans le fichier <$extensionDir/$extensionID.xpi>.$normal"
					let nb+=1
				else
					echo "=> Verification de la compatibilite du module <$currentAddonName> avec Palemoon v$palemoonVersion ..."
#					if [ $(echo $palemoonVersion \< $minPalemoonVersionSupported | bc -l) = 1 ] || [ $(echo $palemoonVersion \> $maxPalemoonVersionSupported | bc -l) = 1 ]
					if [ $(echo $palemoonVersion \< $minPalemoonVersionSupported | bc -l) = 1 ]
					then
						echo $blink$yellowOnRed
						echo "=> ERROR: Palemoon v$palemoonVersion n'est pas supporte par le plugin <$currentAddonName> ($extensionID) qui supporte: $minPalemoonVersionSupported < palemoon > $maxPalemoonVersionSupported.$normal" >&2
						notInstalledPluginList="$notInstalledPluginList $currentAddonName"
						echo
						continue
					fi

					echo "=> Installation du module <$currentAddonName> proprement dite dans <$extensionDir/> ..."
					let nb+=1
#			  		$sudo_cmd rsync -vpt "$xpiFile" $extensionDir/$extensionID.xpi
			  		$sudo_cmd cp -puv "$xpiFile" $extensionDir/$extensionID.xpi
					echo "$greenOnBlue==> DONE.$normal"
				fi
#				$sudo_cmd rm "$xpiFile" $installRDFFileName
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
