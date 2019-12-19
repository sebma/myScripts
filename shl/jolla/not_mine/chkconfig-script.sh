#!/bin/bash

if [ -z $1 ]
then
  echo "*** No options given ***"
elif [ -n $1 ]
then
  param1=$1
  if [ -z $2 ]
  then
    case $param1 in
      "--list") systemctl list-unit-files --type=service(preferred);;
      *)  systemctl is-enabled $param1.service;;
      esac
  elif [ -n $2 ]
  then
    param2=$2
    case $param2 in
      "on") systemctl enable $param1.service ;;
      "off") systemctl disable enable $param1.service ;;
      "--list") ls /etc/systemd/system/*.wants/$param1.service ;;
      "--add") systemctl daemon-reload ;;
   *) echo "unrecognized option $param2";;
    esac
  fi
fi
