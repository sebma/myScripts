#!/usr/bin/env ksh

app=EUR
uname -s | grep -q Linux && echo="echo -e" || echo=echo

scriptParentDir=$(dirname $0)/..
scriptParentDir=$(cd $scriptParentDir;pwd)
logFile=$(basename $0 .sh)_$(date +%Y%m%d_%HH%M).log
mkdir -pvm 757 $scriptParentDir/log
logFullFilePath=$scriptParentDir/log/$logFile

log_error_and_exit() {
  rc=$1
  shift
  $echo "$@" | tee -a $logFullFilePath >&2
  $echo "=> logfile = $logFullFilePath." | tee -a $logFullFilePath >&2
  $echo "=> Return code = $rc." | tee -a $logFullFilePath >&2
  exit $rc
}

echo "=> logFile = $logFullFilePath" | tee -a $logFullFilePath

whoami | egrep -q eur.[12]?adm || log_error_and_exit 1 "=> ERROR: <$0> must be run as the EUR admin account instead of <$USER>."

echo "=> logname = $(logname) tty = $(tty) USER = $USER => Server = $(hostname)" | tee -a $logFullFilePath

#test $REP_APPLICATIF || log_error_and_exit 2 "=> ERROR: $USER's profile has not been loaded."
#test $ENVIRONNEMENT  || log_error_and_exit 2 "=> ERROR: $USER's profile has not been loaded."

uname -s | grep -q Linux || log_error_and_exit 3 "=> ERROR: <$0> must be run on Linux."

hostname | grep -iq "[DHPB]${app}LX[0-9][0-9]" || log_error_and_exit 4 "=> ERROR: You are on server $(hostname), <$0>  must be run on server name: (D|H|P|B)${app}LX0[0-9]."

file=$scriptParentDir/cfg/_livrc.env
test -s "$file" && {
  fileBasename=$(basename "$file")
  test -s $HOME/.liv/$fileBasename && mv -v $HOME/.liv/$fileBasename $HOME/.liv/$fileBasename-$(stat $HOME/.liv/$fileBasename | awk '/Modify/{print$2}')
  cp -pv $file $HOME/.liv/
  chmod -v +x $HOME/.liv/$fileBasename
} 2>&1 | tee -a $logFullFilePath
