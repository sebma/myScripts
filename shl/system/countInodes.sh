#!/usr/bin/env bash

partition=${1:-/}
subDIRList=$(\ls -d */)
for dir in $subDIRList;do
	whatPartition=$(df --output=target $dir | tail -1)
	test $whatPartition == $partition && printf "=> dir = $dir\nInodes = " && sudo find $dir -xdev | wc -l
done
