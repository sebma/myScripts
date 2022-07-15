#!/usr/bin/env bash

exec 3>&1 &> >(tee -a myFile.log) # backup stdout to file descriptor 3 and then redirect stdout to myFile.log via process substitution

myVar1=X.Y.Z.T
echo "=> BEFORE THE LOOP : myVar1 = $myVar1"
for IP;do
	myVar1="$IP"
	echo "=> INSIDE THE LOOP : myVar1 = $myVar1"
	echo ERROR1 >&2
done
echo "=> AFTER THE LOOP : myVar1 = $myVar1"

exec 1>&3 3>&- # restore stdout and close file descriptor 3
