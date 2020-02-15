#!/usr/bin/env bash

fileList=`mktemp`
find . -type f > $fileList
mimeList="application/msword application/pdf application/vnd.ms-office application/vnd.oasis.opendocument.text application/x-elc application/x-executable application/x-gdbm application/x-gzip application/x-object application/x-rpm application/x-sharedlib application/x-shockwave-flash application/x-tar application/x-xz application/xml application/zip audio/midi audio/mpeg audio/x-wav image/gif image/jpeg image/png image/svg+xml image/tiff image/x-ico image/x-xcf text/html text/plain text/troff text/x-c text/x-c++ text/x-java text/x-lisp text/x-mail text/x-pascal text/x-perl text/x-php text/x-shellscript text/x-tex video/x-flv"
while read fileName
do
  for mime in $mimeList
  do
    file -bi $fileName | grep -q $mime && {
      chown seb:users $fileName
      test ! -d $dstDir/$extension/ && mkdir $dstDir/$extension/
      mv -v $fileName $dstDir/$extension/
    }
  done
done < $fileList

