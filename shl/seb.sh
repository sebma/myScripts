#!/usr/bin/env bash

# Launch script for ophcrack livecd
# Version 2.0 for Slitaz distribution

[ "$(lsb_release -si)" = "Ubuntu" ] && MountPointsDir=/media || MountPointsDir=/mnt

#WIN_DIR=( [wW][iI][nN][dD][oO][wW][sS] [wW][iI][nN][nN][tT] [wW][iI][nN][xX][pP] [wW][iI][nN][dD][oO][wW][sS]2003 [wW][iI][nN]2003 [wW][iI][nN]2[kK] )
#SYSTEMCONFIG_DIR=[sS][yY][sS][tT][eE][mM]32/[cC][oO][nN][fF][iI][gG]

# GUI or not ?

if [ "$1" = "0" ]
then
    opts="-g"
else
    opts="-r"
fi

# Preload or not ?
if grep -q "ophcrack=lowram" /proc/cmdline
then
    opts="$opts -p 1"
fi

#Find all the libs

#Check the number of CPUs

numcpu=$(grep -c ^processor /proc/cpuinfo)
let numcpu++

# Get the list of partitions.
DEVICES_LIST=$(ls $MountPointsDir 2>/dev/null)

# Try to find the tables either on the cdrom or on a partition
for DEVICE in $DEVICES_LIST
do 
	if [ -d $MountPointsDir/$DEVICE/tables ]; then
		LIST=$(ls $MountPointsDir/$DEVICE/tables/*/table0.bin 2>/dev/null)
		for TABLE in $LIST
		do
			TABLE=${TABLE%/table0.bin}
			TABLE=${TABLE#/}
			TABLES_DIR[${#TABLES_DIR[*]}]=$TABLE
		done
	fi
done

echo "TABLES_DIR=$TABLES_DIR"
TABLES_DIR=$(locate -r tables/.*table0.bin | xargs -r dirname)
echo "TABLES_DIR=\"$TABLES_DIR\""

if [ ${#TABLES_DIR[*]} = 0 ]; then
	echo "No tables found !!"
    read
    exit 0
else
	echo "Tables found:"
	echo "   ${TABLES_DIR[0]}"
	TABLES_INLINE=${TABLES_DIR[0]}
	for ((  i = 1 ;  i < ${#TABLES_DIR[*]};  i++  ))  
    do
    	echo "   ${TABLES_DIR[i]}"
		TABLES_INLINE="$TABLES_INLINE:${TABLES_DIR[i]}"
    done
	echo
fi

echo "TABLES_INLINE=\"$TABLES_INLINE\""
test -z $TABLES_INLINE && {
  echo "=> TABLES_INLINE is empty"
  exit 1
}

# Try to find Windows hashes
for DEVICE in $DEVICES_LIST
do 
	#for i in 0 1 2 3 4 5	
	#do
		WIN_DIR=$(ls $MountPointsDir/$DEVICE | egrep -i "windows|winnt|winxp|windows2003|win2003|win2k")
		[ -z $WIN_DIR ] && continue
		SYSTEMCONFIG_DIR=$(ls $MountPointsDir/$DEVICE/$WIN_DIR | grep -i ^system32$)
		SYSTEMCONFIG_DIR="$SYSTEMCONFIG_DIR/$(ls $MountPointsDir/$DEVICE/$WIN_DIR/$SYSTEMCONFIG_DIR | grep -i ^config$)"
		DIR="$MountPointsDir/$DEVICE/${WIN_DIR}/$SYSTEMCONFIG_DIR"
		DIR_LS=$(ls -d $DIR 2>/dev/null)
		if [ $DIR_LS ]; then FOUND_DIR[${#FOUND_DIR[*]}]=$DIR_LS; fi
	#done
done

if [ ${#FOUND_DIR[*]} = 0 ]; then
    echo "No partition containing hashes found !!"
    read
    exit 0
elif [ ${#FOUND_DIR[*]} = 1 ]; then
    echo "Found one partition that contains hashes:"
    echo "  ${FOUND_DIR[0]}"
    echo ""
    FOUND=${FOUND_DIR[0]}
else
    echo "List of Windows partitions containing hashes:"
    for ((  i = 0 ;  i < ${#FOUND_DIR[*]};  i++  ))  
      do
      echo "   $i. ${FOUND_DIR[i]}"
    done
    echo ""
    echo "Select the partition to crack: "
    read entry
    FOUND=${FOUND_DIR[$entry]}
fi

echo "Starting Ophcrack"
set -vx
ophcrack -t $TABLES_INLINE -w $FOUND -n $numcpu $opts
set +vx

echo
echo "Shutdown (y/n)?"
read answer
if [ "$answer" = "y" ]; then
    poweroff;
fi
echo "Enter \"poweroff\" to shut down later...";
