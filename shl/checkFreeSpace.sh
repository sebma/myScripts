#!/bin/ksh

set -eu

df=/bin/df
fileSystemName=.
test $1 && fileSystemName=$1
#$df -Pm . | awk '/dev/{print $4" "$NF}' | read freeSpace fileSystem #Ne fonctionne pas en bash
freeSpace=`$df -Pm $fileSystemName | awk '/dev/{print int($4)}'`

minimumFreeSpace=2048
test $freeSpace -lt $minimumFreeSpace && {
  echo "=> ERROR: You need at least $minimumFreeSpace Mo of free space but there is only $freeSpace Mo left on <$fileSystemName> filesystem"
  exit 1
}
