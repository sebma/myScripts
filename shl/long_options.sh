#!/usr/bin/env sh

usage() {
	echo "Usage: $0 [-hv] [-s SERVEUR] [-p DB_PREFIX] [-a actnn] [-c ark|producer ID_CHUNK] [-m all|preing|ing|sto|dm|acc] [-t nh|hm|ns]"

	echo
	echo " -v, --verbose      verbose mode, write log at action level"
	echo " -x, --execution      verbose execution of this script"
	echo " -pl, --listpackages      lists packages involved"
	echo " -s, --server SERVEUR         database server name (default copernic1)"
	echo " -p, --prefix DB_PREFIX       prefix used for db schemas (default pfo)"
	echo " -a, --action ACTION displays on specified action only "
	echo " -m, --module MODULE, display stats on module specified, must be one of all|preing|ing|sto|dm|acc"
	echo " -I, --moduleinstance MODULE, display stats on module instance specified, for instance"
	#  echo " -t, --time nh|hm|ns is the filter on time: the request is on the most recent event, with the -t criter, expressed in hours, minutes, or seconds, default value is 1h"
	echo " -h, --help       display this help"
	echo
}

#GetOptCMD=$(getopt -V | grep -q getopt.*enhanced && getopt || getopts)
getopt -V | grep -q getopt.*util-linux && GetOptCMD=getopt || {
	echo "=> ERROR : You must use getopt from util-linux." >&2
	exit 2
}

shortOptions=":xhvs:p:a:m:t:"
longOptions="(execution)(help)(verbose)(server):(prefix):(action):(module):(time):"
Options=":x(execution)h(help)v(verbose)s:(server)p:(prefix)a:(action)m:(module)t:(time)"

echo $BASH | grep -q bash && {
	GetOptArgs=$shortOptions
	#GetOptArgs="-o $shortOptions --long $longOptions"
	#GetOptCMD=getopt
} || {
	GetOptArgs=$Options
}

while $GetOptCMD $GetOptArgs optionCourrante
do
	case $optionCourrante in
		v|verbose )			VERBOSE=true;;
		h|help    )			usage; exit;;
		x|execution )		set -x;;
		s|server  )			dbHost=$OPTARG;;
		c|criter  )			researchMode=$OPTARG;;
		p|prefix  )			prefixeDb=$OPTARG;;
		m|module  )			module=$OPTARG;;
		I|moduleinstance )	moduleInstance=$OPTARG;;
#		*) idPaquetChunk=$OPTARG;  break;;
		*)			usage; echo "OPTIND=$OPTIND\tOPTARG=$OPTARG"; exit 1;;
	esac
done
shift $(($OPTIND-1))

[ -n "$dbHost" ] && echo "Le serveur de BDD est >$dbHost<"

