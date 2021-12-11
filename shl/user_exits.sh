#!/usr/bin/env bash

test $1 && userList=$@ || userList=$USER

serverList="pingoin01 pingoin02"
for server in $serverList
do
	echo "=> server = $server"
	netcat -v -z -w 5 $server 22 2>&1 | egrep -v "succeeded|open" || ssh -q $server "groups $userList"
done
