#!/bin/bash

# Launch script for ophcrack livecd
# Version 2.0 for Slitaz distribution


WIN_DIR=( [wW][iI][nN][dD][oO][wW][sS] [wW][iI][nN][nN][tT] [wW][iI][nN][xX][pP] [wW][iI][nN][dD][oO][wW][sS]2003 [wW][iI][nN]2003 [wW][iI][nN]2[kK] )

SYSTEMCONFIG_DIR=[sS][yY][sS][tT][eE][mM]32/[cC][oO][nN][fF][iI][gG]

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

numcpu=`cat /proc/cpuinfo | grep ^processor | wc -l`
numcpu=$(( $numcpu + 1 ))

# Get the list of partitions.
DEVICES_LIST=`ls /mnt 2>/dev/null`

# Try to find the tables either on the cdrom or on a partition
for DEVICE in $DEVICES_LIST
do 
	if [ -d /mnt/$DEVICE/tables ]; then
		LIST=`ls /mnt/$DEVICE/tables/*/table0.bin 2>/dev/null`
		for TABLE in $LIST
		do
			TABLE=${TABLE%/table0.bin}
			TABLE=${TABLE#/}
			TABLES_DIR[${#TABLES_DIR[*]}]=$TABLE
		done
	fi
done

if [ ${#TABLES_DIR[*]} = 0 ]; then
	echo "No tables found !!"
    read
    exit 0
else
	echo "Tables found:"
	echo "   /${TABLES_DIR[0]}"
	TABLES_INLINE=${TABLES_DIR[0]}
	for ((  i = 1 ;  i < ${#TABLES_DIR[*]};  i++  ))  
    do
    	echo "   /${TABLES_DIR[i]}"
		TABLES_INLINE="$TABLES_INLINE:${TABLES_DIR[i]}"
    done
	echo
fi

# Try to find Windows hashes
for DEVICE in $DEVICES_LIST
do 
	for i in 0 1 2 3 4 5	
    do
    	DIR="/mnt/$DEVICE/${WIN_DIR[i]}/$SYSTEMCONFIG_DIR"
    	DIR_LS=`ls -d $DIR 2>/dev/null`
    	if [ $DIR_LS ]; then FOUND_DIR[${#FOUND_DIR[*]}]=$DIR_LS; fi
  	done
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

ophcrack -d / -t $TABLES_INLINE -w $FOUND/ -n $numcpu -o /tmp/ophcrack.txt $opts

if [ "$1" = "0" ]; then
    echo "The passwords have been saved in /tmp/ophcrack.txt";
fi
  
echo "Press a key to exit..."
read
echo ""
echo "Shutdown (y/n)?"
read answer
if [ "$answer" = "y" ]; then
    poweroff;
fi
echo "Enter \"poweroff\" to shut down later...";
