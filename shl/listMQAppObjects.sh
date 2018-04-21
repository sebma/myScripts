#!/bin/sh

type sed

set -o nounset
set -o errexit

hostname | grep -q "^d" && listEnv="v|m|i" || listEnv="f|t"
test $# -eq 0 && {
  echo "=> Usage: <$0> <lettre de l'environement:$listEnv>" >&2
  exit 1
}

env=$1
echo $env | egrep -q "$listEnv" || {
  echo "=> ERROR: Wrong environment chosen, please choose between: $listEnv."
  exit 2
}

app=xxx
APP=`echo $app | tr [:lower:] [:upper:]`
APP_PRIVIOUS=YYY
envUpper=`echo $env | tr [:lower:] [:upper:]`
userApplicatif=$app${env}adm

queueManagersList=`\dspmq -o STATUS | sed "s/[()]/ /g" | awk '/Running/{print$2}' | egrep "$APP|$APP_PRIVIOUS$envUpper"`
echo "=> La liste des Queue Managers pour l'environement `echo $userApplicatif | cut -c1-4` est :"
echo $queueManagersList
echo

echo "$queueManagersList" | while read QMGR
do
  echo "=> QMGR = $QMGR"
  echo
  echo "==> Liste des CHANNEL non SYSTEM pour le Queue Manager $QMGR :"
  currentChannelList=`echo "dis chl(*)" | sudo su - $userApplicatif -c "runmqsc -e $QMGR" | awk '/CHANNEL/&&!/SYSTEM/&&!/SGTIG/'`
  echo "$currentChannelList"
  queueList=`echo "dis q(*)" | sudo su - $userApplicatif -c "runmqsc -e $QMGR" | sed "s/[()]/ /g" | awk '/QUEUE/&&!/SYSTEM/&&!/AMQ/&&!/BMC/&&!/DEAD.LETTER/{print$2}'` 
#  echo "=> queueList = $queueList"
  showQueuesSummaryCommand=`echo "$queueList" | sed "s/^/dis q(/;s/$/) TARGET DESCR/"`
#  echo "=> showQueuesSummaryCommand = $showQueuesSummaryCommand"
  echo
  echo "==> Liste des QUEUES non SYSTEM pour le Queue Manager $QMGR :"
  echo "$showQueuesSummaryCommand" | sudo su - $userApplicatif -c "runmqsc -e $QMGR" | awk '/QUEUE|TARGET|DESCR/' | sed "/QUEUE/s/^/\
/"
#  echo "$showQueuesSummaryCommand" | sudo su - $userApplicatif -c "runmqsc -e $QMGR" | awk '/QUEUE|TARGET|DESCR/'
  echo
#    sudo su - $userApplicatif -c "echo 'dis q(*) TARGET DESCR' | runmqsc -e $QMGR" | awk '/QUEUE|TARGET|DESCR/&&!/SYSTEM/&&!/AMQ/&&!/BMC/&&!/DEAD.LETTER/'
#   for queue in $queueList
#   do
#    sudo su - $userApplicatif -c "echo 'dis q($queue) TARGET DESCR' | runmqsc -e $QMGR" | awk '/QUEUE|TARGET|DESCR/'
#    echo
#  done
#  simplifiedChannelList=`echo "$currentChannelList" | sed "s/[()]/ /g" | awk '/CHANNEL/&&!/SYSTEM/{print$2}'`
#  echo "===> Simplified CHANNEL List = $simplifiedChannelList"
#  for qmgrChannel in $simplifiedChannelList
#  do
#    echo "====> QMGR: $QMGR, qmgrChannel = $qmgrChannel"
#  done
done

