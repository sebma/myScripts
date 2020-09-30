#!/usr/bin/env sh

hw-probeAddNodeToInventory ()
{
	local inventoryID=null
	if [ $# = 0 ]; then
		inventoryID="LHW-8028-0102-D496-15BF"
	else
		if [ $# = 1 ]; then
			inventoryID=$1
		else
			echo "=> $FUNCNAME [inventoryID]" 1>&2
			return 1
		fi
	fi
	\sudo -E \hw-probe -all -upload -i $inventoryID && echo "=> INFO: Check your email to add confirm adding the new node to your inventory : https://linux-hardware.org/index.php?view=computers&inventory=$inventoryID" 1>&2
}

hw-probeAddNodeToInventory "$@"
