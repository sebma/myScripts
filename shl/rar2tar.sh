#!/usr/bin/env bash

cd ~/Desktop

[ ! -d RAR ] && mkdir RAR
[ ! -d TAR ] && mkdir TAR

mkdir /tmp/tmp
for file in $(ls -1 RAR/*.rar 2>/dev/null)
do
set -x
  FileBasename="$(basename "$file" .rar)"
  ContainingDir="$(unrar vb $file | tail -1)"

  unrar x "$file" /tmp/tmp
  cd /tmp/tmp
  tar -cvf $HOME/Desktop/TAR/${FileBasename}.tar "$ContainingDir"
  cd -
  echo rm -fr $FileBasename
done

set +x
