#!/usr/bin/env ksh

runmqsc() {
  local mqmUser=mqm
#  local APP_USER=
  local runmqsc=$(sudo su - $mqmUser -c "which runmqsc")
  sudo su - $APP_USER -c "$runmqsc -e $@"
}

browseq() {
  local rangeSeparator="\." #Regualar expression
  test $# -lt 2 && {
    echo "=> Usage: $FUNCNAME <qmanager> <qname> [<x$(eval echo $rangeSeparator$rangeSeparator)y>]" >&2
    return 1
  }

  local qMgr=$1
  local qName=$2
  local qloadTool=$HOME/bin/qload
  local mqmUser=mqm
  local inf=1 sup=1

  test $# = 3 && {
    inf=$(echo $3 | awk -F"$rangeSeparator" '{print $1}')
    sup=$(echo $3 | awk -F"$rangeSeparator" '{print $NF}')
  }

  local -i i=$inf
  while [ $i -le $sup ]
  do
    echo "=> Message #$i:" 1>&2
#set -x
    sudo su $mqmUser -c "$qloadTool -q -m $qMgr -i $qName -f stdout -d a -r $i" 2>/dev/null | awk '/^X /{print$NF}' | sed "s/^<//;s/>$//" | tr -d "\n"
set +x
    echo
    echo
    let i+=1
  done
}

#alias lsqm='dspmq | sed "s/[()]/ /g" | awk "/Running/{print \$2}" | paste -sd" ";echo'
lsqm() {
  local queueManager=$1
  local runmqsc=$(sudo su - $mqmUser -c "which runmqsc")

  test $queueManager && echo dis qmgr | sudo su $mqmUser -c "$runmqsc -e $queueManager" || {
    echo "Usage: $FUNCNAME [ <QueueManager> ]" >&2
    echo "=> You must choose a queue manager among the following :" >&2
    echo
    dspmq | sed "s/[()]/ /g" | awk '/Running/{print $2}' | paste -sd" "
    echo
    return 1
  }
}

channelstatus() {
  local queueManager=$1
  local runmqsc=$(sudo su - $mqmUser -c "which runmqsc")

  test $queueManager && {
    echo dis chs"(*)" | sudo su $mqmUser -c "$runmqsc -e $queueManager"
    true
  } || {
    echo "Usage: $FUNCNAME [ <QueueManager> ]" >&2
    echo "=> You must choose a queue manager among the following :" >&2
    echo
    dspmq | sed "s/[()]/ /g" | awk '/Running/{print $2}' | paste -sd" "
    echo
    return 1
  }
}
  
lschannels() {
  local queueManager=$1
  local channelList=""
  local currentChannel=""
  local runmqsc=$(sudo su - $mqmUser -c "which runmqsc")

#  test $queueManager && echo 'dis chl(*)' | sudo su $mqmUser -c "$runmqsc -e $queueManager" | awk '/CHANNEL/&&!/SYSTEM/&&!/SGTIG/'
  test $queueManager && {
    test $2 && {
      channelName=$2
      echo "dis chl($channelName)" | sudo su - $mqmUser -c "$runmqsc -e $queueManager" || {
        errCode=$?
        echo
        echo "=> ERROR The channel $channelName does not belong to $queueManager." >&2
        echo "=> You must choose another queue manager among the following :" >&2
        echo
        dspmq | sed "s/[()]/ /g" | awk '/Running/{print $2}' | paste -sd" "
        echo
        return $errCode
      }
    } || {
      channelList=`echo 'dis chl(*)' | sudo su $mqmUser -c "$runmqsc -e $queueManager" | sed "s/[()]/ /g" | awk '/CHANNEL/&&!/SYSTEM/&&!/SGTIG/{print$2}'`
      for currentChannel in $channelList
      do
        echo "=> currentChannel = $currentChannel"
        echo dis chl"($currentChannel) conname descr xmitq" | sudo su $mqmUser -c "$runmqsc -e $queueManager" | awk '/CHLTYPE|CONNAME|DESCR|XMITQ/'
        echo
      done
    }
  } || {
    echo "Usage: $FUNCNAME <QueueManager> [ <ChannelName> ]" >&2
    echo "=> You must choose a queue manager among the following :" >&2
    echo
    dspmq | sed "s/[()]/ /g" | awk '/Running/{print $2}' | paste -sd" "
    echo
    return 1
  }
}

lsq() {
  local queueManager=$1
  local runmqsc=$(sudo su - $mqmUser -c "which runmqsc")

  test $queueManager && {
    test $2 && {
      queueName=$2
      echo "dis q($queueName) target curdepth descr rqmname rname usage xmitq" | sudo su - $mqmUser -c "$runmqsc -e $queueManager" || {
        errCode=$?
  echo
        echo "=> ERROR The queue $queueName does not belong to $queueManager." >&2
        echo "=> You must choose another queue manager among the following :" >&2
        echo
        dspmq | sed "s/[()]/ /g" | awk '/Running/{print $2}' | paste -sd" "
        echo
  return $errCode
      }
    } || {
      queueList=`echo "dis q(*)" | sudo su - $mqmUser -c "$runmqsc -e $queueManager" | sed "s/[()]/ /g" | awk '/QUEUE/&&!/SYSTEM/&&!/AMQ/&&!/BMC/&&!/DEAD.LETTER/{print$2}'`
      test "$queueList" && {
        showQueuesSummaryCommand=`echo "$queueList" | sed "s/^/dis q(/;s/$/) target curdepth descr rqmname rname usage xmitq/"`
        echo "==> Liste des QUEUES non SYSTEM pour le Queue Manager $queueManager :"
        echo "$showQueuesSummaryCommand" | sudo su - $mqmUser -c "$runmqsc -e $queueManager" | awk '/QUEUE|TARGET|CURDEPTH|DESCR|RQMNAME|RNAME|USAGE|XMITQ/' | sed "/^ *QUEUE/s/^/\\$(printf '\n\a')/"
      } || return
    }
  } || {
    echo "Usage: $FUNCNAME <QueueManager> [ <QueueName> ]" >&2
    echo "=> You must choose a queue manager among the following :" >&2
    echo
    dspmq | sed "s/[()]/ /g" | awk '/Running/{print $2}' | paste -sd" "
    echo
    return 1
  }
}

lsqa() {
  local queueManager=$1
  local runmqsc=$(sudo su - $mqmUser -c "which runmqsc")

  test $queueManager && {
    test $2 && {
      queueName=$2
      echo "dis q($queueName) target descr" | sudo su - $mqmUser -c "$runmqsc -e $queueManager" || {
        errCode=$?
        echo
        echo "=> ERROR The queue $queueName does not belong to $queueManager." >&2
        echo "=> You must choose another queue manager among the following :" >&2
        echo
        dspmq | sed "s/[()]/ /g" | awk '/Running/{print $2}' | paste -sd" "
        echo
        return $errCode
      }
    } || {
      queueList=`echo "dis qa(*)" | sudo su - $mqmUser -c "$runmqsc -e $queueManager" | sed "s/[()]/ /g" | awk '/QUEUE/&&!/SYSTEM/&&!/AMQ/&&!/BMC/&&!/DEAD.LETTER/{print$2}'`
      test "$queueList" && {
        showQueuesSummaryCommand=`echo "$queueList" | sed "s/^/dis qa(/;s/$/) target descr/"`
        echo "==> Liste des QUEUES non SYSTEM pour le Queue Manager $queueManager :"
        echo "$showQueuesSummaryCommand" | sudo su - $mqmUser -c "$runmqsc -e $queueManager" | awk '/QUEUE|TARGET|DESCR/' | sed "/^ *QUEUE/s/^/\\$(printf '\n\a')/"
      } || return
    }
  } || {
    echo "Usage: $FUNCNAME <QueueManager> [ <QueueName> ]" >&2
    echo "=> You must choose a queue manager among the following :" >&2
    echo
    dspmq | sed "s/[()]/ /g" | awk '/Running/{print $2}' | paste -sd" "
    echo
    return 1
  }
}

lsql() {
  local queueManager=$1
  local runmqsc=$(sudo su - $mqmUser -c "which runmqsc")

  test $queueManager && {
    test $2 && {
      queueName=$2
      echo "dis q($queueName) curdepth descr" | sudo su - $mqmUser -c "$runmqsc -e $queueManager" || {
        errCode=$?
        echo
        echo "=> ERROR The queue $queueName does not belong to $queueManager." >&2
        echo "=> You must choose another queue manager among the following :" >&2
        echo
        dspmq | sed "s/[()]/ /g" | awk '/Running/{print $2}' | paste -sd" "
        echo
        return $errCode
      }
    } || {
      queueList=`echo "dis ql(*)" | sudo su - $mqmUser -c "$runmqsc -e $queueManager" | sed "s/[()]/ /g" | awk '/QUEUE/&&!/SYSTEM/&&!/AMQ/&&!/BMC/&&!/DEAD.LETTER/{print$2}'`
      test "$queueList" && {
        showQueuesSummaryCommand=`echo "$queueList" | sed "s/^/dis ql(/;s/$/) curdepth descr/"`
        echo "==> Liste des QUEUES non SYSTEM pour le Queue Manager $queueManager :"
        echo "$showQueuesSummaryCommand" | sudo su - $mqmUser -c "$runmqsc -e $queueManager" | awk '/QUEUE|CURDEPTH|DESCR/' | sed "/^ *QUEUE/s/^/\\$(printf '\n\a')/"
      } || return
    }
  } || {
    echo "Usage: $FUNCNAME <QueueManager> [ <QueueName> ]" >&2
    echo "=> You must choose a queue manager among the following :" >&2
    echo
    dspmq | sed "s/[()]/ /g" | awk '/Running/{print $2}' | paste -sd" "
    echo
    return 1
  }
}

lsqr() {
  local queueManager=$1
  local runmqsc=$(sudo su - $mqmUser -c "which runmqsc")

  test $queueManager && {
    test $2 && {
      queueName=$2
      echo "dis q($queueName) descr rqmname rname xmitq" | sudo su - $mqmUser -c "$runmqsc -e $queueManager" || {
        errCode=$?
        echo
        echo "=> ERROR The queue $queueName does not belong to $queueManager." >&2
        echo "=> You must choose another queue manager among the following :" >&2
        echo
        dspmq | sed "s/[()]/ /g" | awk '/Running/{print $2}' | paste -sd" "
        echo
        return $errCode
      }
    } || {
      queueList=`echo "dis qr(*)" | sudo su - $mqmUser -c "$runmqsc -e $queueManager" | sed "s/[()]/ /g" | awk '/QUEUE/&&!/SYSTEM/&&!/AMQ/&&!/BMC/&&!/DEAD.LETTER/{print$2}'`
      test "$queueList" && {
        showQueuesSummaryCommand=`echo "$queueList" | sed "s/^/dis qr(/;s/$/) descr rqmname rname xmitq/"`
        echo "==> Liste des QUEUES non SYSTEM pour le Queue Manager $queueManager :"
        echo "$showQueuesSummaryCommand" | sudo su - $mqmUser -c "$runmqsc -e $queueManager" | awk '/QUEUE|DESCR|RQMNAME|RNAME|XMITQ/' | sed "/^ *QUEUE/s/^/\\$(printf '\n\a')/"
      } || return
    }
  } || {
    echo "Usage: $FUNCNAME <QueueManager> [ <QueueName> ]" >&2
    echo "=> You must choose a queue manager among the following :" >&2
    echo
    dspmq | sed "s/[()]/ /g" | awk '/Running/{print $2}' | paste -sd" "
    echo
    return 1
  }
}

lscurdepth() {
  local queueManager=$1
  local queueName
  local runmqsc=$(sudo su - $mqmUser -c "which runmqsc")
  local queueManagerList=$(dspmq | sed "s/[()]/ /g" | awk '/Running/{print $2}')

  test $queueManager && {
    echo $queueManagerList | grep -q $queueManager || {
      echo "=> ERROR: The queue manager $queueManager does not exist, please choose among the following queue managers: "
      echo
      echo $queueManagerList
      return 1
    }
    test $2 && {
      queueName=$2
      echo "dis qs($queueName) ipprocs lgetdate lgettime lputdate lputtime" | sudo su - $mqmUser -c "$runmqsc -e $queueManager" || {
        errCode=$?
        echo
        echo "=> ERROR The queue $queueName does not belong to $queueManager." >&2
        echo "=> You must choose another queue manager among the following :" >&2
        echo
        echo $queueManagerList
        echo
        return $errCode
      }
    } || {
      queueList=`echo "dis ql(*)" | sudo su - $mqmUser -c "$runmqsc -e $queueManager" | sed "s/[()]/ /g" | awk '/QUEUE/&&!/SYSTEM/&&!/AMQ/&&!/BMC/&&!/DEAD.LETTER/{print$2}'`
      test "$queueList" && {
        showQueuesSummaryCommand=`echo "$queueList" | sed "s/^/dis qs(/;s/$/) ipprocs lgetdate lgettime lputdate lputtime where(curdepth ne 0)/"`
        echo
        echo "==> Liste des QUEUES non SYSTEM pour le Queue Manager $queueManager :"
        echo "$showQueuesSummaryCommand" | sudo su - $mqmUser -c "$runmqsc -e $queueManager" | awk '/QUEUE|CURDEPTH|GET|PUT/' | sed "/^ *QUEUE/s/^/\\$(printf '\n\a')/"
      } || return
    }
  } || {
    echo "Usage: $FUNCNAME <QueueManager> [ <QueueName> ]" >&2
    echo "=> You must choose a queue manager among the following :" >&2
    echo
    echo $queueManagerList
    echo
    return 1
  }
}

