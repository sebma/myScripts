#!/usr/bin/env bash

omreport chassis info
omreport system version

time racadm getsysinfo -4
time racadm get iDRAC.IPv4.Address
time racadm storage get controllers -o -p name,currentcontrollermode
time racadm raid get vdisks -o -p status,name,rollupstatus,state,layout | grep -5 Failed
time racadm raid get pdisks -o -p status,name,rollupstatus,state | grep -1 Failed

omreport storage pdisk controller=0 -fmt ssv | grep -wv Ok
echo
omreport storage vdisk controller=0 -fmt ssv | grep -wv Ok
echo

perccli=$(ls /opt/MegaRAID/perccli/perccli64)
$perccli /c0/eall/sall show J | jq -r '.Controllers[]."Response Data"."Drive Information"[] | select(.State == "Failed")'
echo
$perccli /c0/vall show J | jq -r '.Controllers[]."Response Data"."Virtual Drives"[] | select(.State == "OfLn")'
echo
## AFTER REPLACE ##
# $perccli /c0/eall/sall show J | jq -r '.Controllers[]."Response Data"."Drive Information"[] | select(.State == "UGood")'
