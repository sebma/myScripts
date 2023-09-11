#!/usr/bin/env bash

#omreport=$(find /opt/ -xdev -type f -name "*omreport")
omreport=/opt/dell/srvadmin/bin/omreport

if test -x $omreport && ! egrep -i "vmware|virtal" /sys/class/dmi/id/sys_vendor /sys/class/dmi/id/product_name -q ;then
	echo "=> Mailing bad disks list :"
	badDisksCount=$($omreport storage pdisk controller=0 -fmt ssv | grep ';Critical;' | wc -l)
	badDisksList=$($omreport storage pdisk controller=0 -fmt ssv | grep -B20 ';Critical;' | egrep '^ID|;Critical;' | awk -F";" '{print$1";"$2";"$3";"$4";"$6";"$7";"$10";"$21";"$25";"$26";"$27}')
	Recipients=sebmansfeld@yahoo.fr
	CCs=""
	if [ $badDisksCount != 0 ];then
		echo -e "
Bonjour, si il y a un qui a le courage d'aller au datacenter pour aller changer le(s) disque(s) suivant(s) sur $HOSTNAME :-) :\n
$badDisksList
" | mail -s "Subject: Bad disks on $HOSTNAME" -c "$CCs" $Recipients
	fi
fi
