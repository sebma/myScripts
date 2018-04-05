#!/usr/bin/env ksh

scriptPath=$PWD/$(dirname $0)
logFile=$(basename $0 .sh)_$(date +%Y%m%d_%HH%M).log
mkdir -pvm 757 $scriptPath/log

echo $USER | grep -q eur.adm || {
  echo "=> ERROR: <$0> must be run as eurfadm or eurtadm or eurpadm instead of <$USER>." | tee $scriptPath/log/$logFile >&2
  exit 1
}

test $REP_APPLICATIF || {
  echo "=> ERROR: $USER 's profile has not been loaded." | tee -a $scriptPath/log/$logFile >&2
  exit 2
}

test $ENVIRONNEMENT || {
  echo "=> ERROR: $USER's profile has not been loaded." | tee -a $scriptPath/log/$logFile >&2
  exit 2
}

for file
do
  cp -pv $file $REP_APPLICATIF/${ENVIRONNEMENT}adm/
  chmod +x $REP_APPLICATIF/${ENVIRONNEMENT}adm/$file
done 2>&1 | tee -a $scriptPath/log/$logFile
