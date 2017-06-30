#!/bin/ksh
#X064304
#MANSFELD Sebastien

[ $# -ne 1 ] && {
  echo "Usage: $0 <route_file>" >&2
  exit 1
}

route_file="$1"

[ ! -s $route_file ] && {
  echo "ERROR: The file $route_file is empty or does not exist" >&2
  exit 2
}

IPRegExp="([0-9]{1,3}[.]){3}[0-9]{1,3}"

echo "=> testRouteCommand :"

type telnet 2>/dev/null && testRouteCommand=telnet
type nc 2>/dev/null && testRouteCommand=nc
type netcat 2>/dev/null && testRouteCommand=netcat

#grep -v "^[ 	]*$" $route_file | while read dest port
egrep "^${IPRegExp}[ 	][0-9]+$" $route_file | while read dest port
do
  opened=false
  echo
  echo "=> Testing TCP route to $dest $port ..."
  echo "\035\nq" | $testRouteCommand $dest $port | grep Connected & && {
    bOpened=true
    echo "=> The route to $dest $port is opened"
  }
  test ! $opened && sleep 5 && pkill telnet && echo "=> The route to $dest $port is closed"
done
