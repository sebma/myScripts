#!/usr/bin/env bash

anyTimeWithTZ2LocalTimeZone ()
{
	local remoteTime=to_be_defined
	local remoteTZ=to_be_defined
	local destinationTZ
	local date=date
#	local localTZ=$(date +%Z)
	local localTZ=CET
	test $osFamily = Darwin && date=gdate
	if [ $# = 0 ]; then
		echo "=> Usage : $FUNCNAME remoteTime [destinationTZ=$localTZ]" 1>&2
		return 1
	else
		if [ $# = 1 ]; then
			case $1 in
				-h | --h | -help | --help)
					echo "=> Usage : $FUNCNAME remoteTime [destinationTZ=$localTZ]" 1>&2
					return 1
					;;
				*)
					remoteTime=$1
					destinationTZ=$localTZ
					;;
			esac
		else
			remoteTime=$1
			destinationTZ=$2
		fi
	fi
	remoteTime=${remoteTime/./:}
	remoteTZ=$(echo $remoteTime | awk '{printf$NF}')
	case $remoteTZ in
		AT)
			remoteTZ=$(TZ=Canada/Atlantic date '+%Z')
			remoteTime=${remoteTime/ AT/ $remoteTZ}
			;;
		CT)
			remoteTZ=$(TZ=US/Central date '+%Z')
			remoteTime=${remoteTime/ CT/ $remoteTZ}
			;;
		ET)
			remoteTZ=$(TZ=US/Eastern date '+%Z')
			remoteTime=${remoteTime/ ET/ $remoteTZ}
			;;
		PT)
			remoteTZ=$(TZ=US/Pacific date '+%Z')
			remoteTime=${remoteTime/ PT/ $remoteTZ}
			;;
		AET)
			remoteTZ=$(TZ=Australia/Sydney date '+%Z')
			remoteTime=${remoteTime/ AET/ $remoteTZ}
			;;
		CET)
			remoteTZ=$(TZ=CEST date '+%Z')
			remoteTime=${remoteTime/ CET/ $remoteTZ}
			;;
		*)

		;;
	esac
	TZ=$destinationTZ $date -d "$remoteTime"
}

anyTimeWithTZ2LocalTimeZone "$@"
