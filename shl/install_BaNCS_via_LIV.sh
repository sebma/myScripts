#!/usr/bin/env ksh

#set -x
set -o errexit
set -o nounset

progBaseName=$(basename $0)
logFile=$HOME/log/${progBaseName}_$(date +%Y%m%d_%HH%M_%S).log

#function initLog {
	#Duplication de stdout et de stderr sans perdre le contenu de mes variables lors de l'utilisation d'un " | tee ....."
	mkdir -p $(dirname $logFile)
	mkfifo $logFile.pipe $logFile-err.pipe
	tee -a $logFile < $logFile.pipe &
	stdout_tee_PID=$!
	tee -a $logFile < $logFile-err.pipe >&2 &
	stderr_tee_PID=$!

	# Passage des PID a la fonction appelante via stdout
	echo $stdout_tee_PID $stderr_tee_PID

	exec 1> $logFile.pipe
	exec 2> $logFile-err.pipe
#}

function endLogAndExit {
	typeset stdout_tee_PID=$1
	typeset stderr_tee_PID=$2
	RC=$3

	echo "=> <$progBaseName> a retourne le code <$RC>."
	echo
	echo "=> The log file is <$logFile>." >&2

set -x
	exec 1>&- 2>&-
	wait $stdout_tee_PID
	wait $stderr_tee_PID
	rm -f $logFile.pipe $logFile-err.pipe
	chmod -w $logFile
	echo "=> Taille du fichier <logFile> ..."
	du -h $logFile
	exit $RC
}

environment=$1
version=$2
app=$(echo $environment | cut -c-3)

#PIDList=$(initLog)
PIDList="$stdout_tee_PID $stderr_tee_PID"

echo "=> Lancement du programme de la maniere suivante: $progBaseName $@ ..."

if [ $# != 2 ]
then
	echo "=> Usage: $progBaseName <environment> <version to install>." >&2
	endLogAndExit $PIDList 1
fi

case $environment in
	eurv1|euri1)
		ls
		isCuster=false
		APSServerList=d${app}lx01
		BIRServer=d${app}lx01
	;;
	eurv2|eurd1)
		isCuster=false
		APSServerList=d${app}lx02
		BIRServer=d${app}lx02
	;;
	eurf|eurt)
		isCuster=true
		APSServerList="h{$app}lx01 h{$app}lx02"
		BIRServer=h${environment}03f
	;;
	eurp)
		isCuster=true
		APSServerList="p{$app}lx01 p{$app}lx02"
		BIRServer=p${environment}03f
	;;
	all)
		echo "=> NOT YET IMPLEMENTED." >&2
		endLogAndExit $PIDList 2
	;;
	*)
		echo "=> The $environment environment does not exist or does not belong to us." >&2
		endLogAndExit $PIDList 3
	;;
esac

mainVersion=$(echo $version | cut -d. -f1-3)
for APSServer in $APSServerList
do
	ssh -t $APSServer "
		sudo su - ${environment}adm -c \"
			liv vs APS_$mainVersion
			liv infos search $version | grep -q $version || {
				rm -f ~/version/.Installfile.csv
				echo '=> ERROR: La synchro de <APS_'$mainVersion'> a pas ete faite'
				exit 1
			}
			liv install search $version
			# Nous envoyer l'output des deux commandes suivantes :
			liv fi search $version
			cat ~/bancs_version
		\"
	"
done

ssh -t $BIRServer "
	sudo su - ${environment}adm -c \"
		liv vs BIR_$mainVersion
		liv infos search $version | grep -q $version || {
			rm -f ~/version/.Installfile.csv
			echo '=> ERROR: La synchro de <BIR_'$mainVersion'> a pas ete faite'
			exit 1
		}
		liv install search $version
		# Nous envoyer l'output des deux commandes suivantes :
		liv fi search $version
		cat ~/bancs_version
	\"
"

endLogAndExit $PIDList $?
