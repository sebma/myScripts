#!/usr/bin/env sh

set -o nounset

LANG=C
toolList="dmidecode lshw"
#type $toolList | grep found && exit 1

rc=0
for tool in $toolList
do
  type $tool >/dev/null || {
    rc=$?
    echo "=> ERROR: $tool is not installed." >&2
  }
done
test $rc != 0 && exit

assetTag=`sudo dmidecode -s chassis-asset-tag | egrep -v "Not Specified|^(Asset.|ATN)1234567890"`
reportFile="`sudo dmidecode -s system-manufacturer | sed 's/ Inc.\| INC.//'`__`sudo dmidecode -s system-product-name`__`sudo dmidecode -s baseboard-product-name`"
test "$assetTag" && reportFile=${reportFile}__$assetTag
reportFile="${reportFile}__`basename $0 .sh`_sh__`lsb_release -sd`"
reportFile="`echo $reportFile | sed 's/ \|(\|\./_/g;s/)//g'`.txt"

rc=0
sudo rm -f "$reportFile"
test -f "$reportFile" || {
  #set -x
  socket=`sudo dmidecode -t processor | awk -F": " '/Upgrade: Socket|Socket Designation:/{print$2}' | egrep -wv "CPU"`
  test "$socket" || socket=`sudo lshw -c processor | awk -F": " '/slot/{print$2}' | egrep -wv "CPU"`
  test "$socket" || {
    type x86info || {
       wget -qO/dev/null www.google.com && sudo apt-get install -qqy x86info || exit
     }
    socket=`x86info -a 2>/dev/null | awk -F": " '/Connector type:/{print$2}'`
    rc=$?
  }
  set +x
  echo "=> Socket = $socket"
  echo
  echo "=> The report file $reportFile"
} 2>&1 | sudo tee -a "$reportFile"

exit $rc
