#!/usr/bin/env ksh

myPID=$$
scriptName=$(basename $0)
sudo=""
type sudo >/dev/null 2>&1 && sudo=$(which sudo)
#set -o nounset
#set -o errexit

pgrep gpm >/dev/null || $sudo service gpm start

test $# = 0 && diskDevice=sda || diskDevice=$1
if ! echo $diskDevice | grep -q /dev/; then 
	diskDevice=/dev/$diskDevice
fi

diskModel=$($sudo smartctl -i $diskDevice | awk '/Model:/{print$NF}')
test -z $diskModel && exit
diskFamily="$($sudo smartctl -i $diskDevice |  awk '/Family:/{for(i=3;i<NF;++i)printf $i" ";print$i}')"
logFile=$(echo read_write_speed_$diskFamily $diskModel | sed "s/[ .\"]/_/g").log

{
	echo "=> First read speed test SMART on disk $diskFamily $diskModel on $diskDevice :"
	$sudo hdparm -t --direct $diskDevice
	echo
	echo "=> Second read speed test SMART on disk $diskFamily $diskModel on $diskDevice :"
	$sudo hdparm -t -T $diskDevice
	echo
} 2>&1 | tee $logFile

sync
tmpDevice=$(df /tmp | awk '/tmp/{print$1}')
tmpVG="$(sudo lvdisplay -c $tmpDevice | cut -d: -f2)"
#set -x
if df $tmpDevice | grep -q $diskDevice || sudo pvdisplay -c | grep -q $diskDevice.*VG_ALL
then
#set +x
	echo "=> Write speed test SMART on disk $diskFamily $diskModel on $diskDevice :" | tee -a $logFile
	echo | tee -a $logFile
	dd if=/dev/zero of=/tmp/bf bs=8k count=500000 > $HOME/write_test_$diskModel.log 2>&1 &
	ddPID=$!
	echo "=> Sleeping 5 seconds ..." | tee -a $logFile
	sleep 5
	kill -USR1 $ddPID
	sleep 1
	kill $ddPID
	sync
	rm -v /tmp/bf
	test -s $HOME/write_test_$diskModel.log && cat $HOME/write_test_$diskModel.log >> $logFile
	ls -l $HOME/write_test_$diskModel.log
	rm -v $HOME/write_test_$diskModel.log
fi
echo
echo "=> logFile = $logFile"
