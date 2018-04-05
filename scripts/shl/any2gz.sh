#!/bin/sh

trap 'echo "===> Program interrupted by CTRL+C" >&2 && exit 3' SIGINT

extract () {
  local archive=$1
  local txtfile=""
  case `file -b -i $archive | cut -d, -f1` in
    application/x-compress) txtfile=`uncompress -v $archive  2>&1 | awk '{print $NF}'`  ;;
    application/x-gzip)     txtfile=`gunzip -v $archive 2>&1 | awk '{print $NF}'`	;;
    application/x-bzip2)    txtfile=`bunzip2 $archive`					;;
    application/x-zip)      txtfile=`unzip $archive | awk '/inflating/{print $NF}'`	;;
    application/x-rar)      txtfile=`unrar x $archive | awk '/Extracting  /{print $2}'`	;;
    *)           echo "'$archive': unrecognized file compression" ;;
  esac
  file -b -i $txtfile | cut -d, -f1 | grep -q application/x-tar && txtfile=`tar xvf $archive`
  echo $txtfile
}

[ $# -lt 2 ] && {
  echo "Usage: $0 <fic1.zip> <fic2.zip> ..." >&2
  exit 1
}

shift
for file
do
  [ -f $file ] && {
    cp "$file" /tmp/
    cd /tmp
    txtfile=`extract "$file"`
    test ! $? || {
      echo "==> Error: Invalid zip format in file : $file, skipping $file ..." >&2
      echo
      continue
    }
    dos2unix "$txtfile"
    echo "=> Deleting blank lines in $txtfile ..."
    time sed -i "/^[\t ]*$/d" "$txtfile"
    echo "=> Compressing $txtfile ..."
    gzip -9v "$txtfile"
    echo
  } || {
    echo "\`$file' is not a valid file"
  }
done

