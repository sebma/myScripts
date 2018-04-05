#!/usr/bin/env ksh

logfile=mylogfile
test -e $logfile && rm $logfile
mkfifo ${logfile}.pipe ${logfile}.pipe2
tee $logfile < ${logfile}.pipe &
tee -a $logfile < ${logfile}.pipe2 >&2 &
exec > ${logfile}.pipe
exec 2> ${logfile}.pipe2

echo COUCOU1
echo ERROR >&2
a=debut
if [ $a = debut ]
then
  a=milieu
  echo Dans le if
else
  a=0
fi
echo "=> a = $a"
rm ${logfile}.pipe ${logfile}.pipe2
#rm ${logfile}.pipe

