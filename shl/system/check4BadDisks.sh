#!/usr/bin/env bash

function lsdisks {
        \ls /sys/class/block/ | sed "s|^|/dev/|" | egrep -v '/(loop|dm-|md|sr|z?ram|sd[a-z]+[0-9]+|nvme[0-9]n[0-9]p[0-9]|synoboot[0-9])'
}

test $(id -u) == 0 && sudo="" || sudo=sudo
for disk in $(lsdisks);do
        smartBadsectors=$($sudo smartctl -A $disk | awk '/Reallocated_Sector_Ct|Current_Pending_Sector|Offline_Uncorrectable/{bad+=$NF}END{printf bad}')
        if [ $smartBadsectors != 0 ];then
                echo "=> WARNING : $disk has $smartBadsectors." | mail -s "WARNING : $disk has $smartBadsectors." g.makridis@ellipseanimation.com -c s.mansfeld@pluriad.fr
        fi
done
