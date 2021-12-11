#!/usr/bin/env bash

local gnuFileUtils="chcon chgrp chown chmod cp dd df dir dircolors install ln ls mkdir mkfifo mknod mktemp mv rm rmdir shred sync touch truncate vdir"
local fileUtils="chgrp|chown|chmod|cp|dd|df|install|ln|ls|mkdir|mkfifo|mknod|mv|rm|rmdir|sync|touch"
local gnuTextUtils="base64 cat cksum comm csplit cut expand fmt fold head join md5sum nl od paste ptx pr sha1sum sha224sum sha256sum sha384sum sha512sum shuf sort split sum tac tail tr tsort unexpand uniq wc"
local textUtils="cat|cksum|comm|csplit|cut|expand|fmt|fold|head|join|md5sum|nl|od|paste|ptx|pr|sort|split|sum|tail|tr|tsort|unexpand|uniq|wc"
local gnuShellUtils="arch basename chroot date dirname du echo env expr factor false groups hostid id link logname nice nohup pathchk pinky printenv printf pwd readlink runcon seq sleep stat stty su tee test timeout true tty uname unlink uptime users who whoami yes"
local shellUtils="basename|chroot|date|dirname|du|echo|env|expr|factor|false|groups|hostid|id|link|logname|nice|nohup|pathchk|printenv|printf|pwd|sleep|stty|su|tee|test|true|tty|uname|unlink|uptime|users|who|whoami|yes"
local shellBuiltins="echo|type|test|while|read|for|do|done|case|esac|set"
local otherUtils="awk"

test $1 && scriptFileName=$1 || {
  echo "=> Usage: <$0> <script_name.sh>" >&2
  exit 1
}

type perl >/dev/null 2>&1 || {
  echo "=> ERROR: <perl> is needed" >&2
  exit 2
}

PATH=$PATH:$TUXDIR/bin

# perl -pe "s/(df|awk)\s+[^|]+/\1 /"
while read line
do
  currentWordList=`echo $line | egrep -wv "function|typeset|local" | perl \
-pe "s/^\s*//;" \
-pe "s/#.*//;" \
-pe "s/^\s*exit [0-9]*\s*//;" \
-pe "s/($fileUtils|$textUtils|$shellUtils|$otherUtils)\s+[^|]+/\1 /g;" \
 | grep ""`

#  test "$currentWordList" && echo "=> currentWordList = \"$currentWordList\""
  test "$currentWordList" && echo $currentWordList
done < $scriptFileName
#done < $scriptFileName | tr " " "\n" | sort -u | xargs -l type >/dev/null
#done < $scriptFileName | tr " " "\n" | sort -u

echo
#local functionList=`grep "function " $scriptFileName | perl -pe "s/^.*function\s*//;s/\s*{//;s/\n/ /"`
#echo "=> functionList = $functionList"
