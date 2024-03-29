#!/usr/bin/env bash

hw_probeAddNodeToInventory ()
{
	local inventoryID=null
	if ! type -P hw-probe >/dev/null 2>&1;then
		echo "=> ERROR [$FUNCNAME] : You must first install <hw-probe>." >&2
		return 1
	fi

	if [ $# = 0 ]; then
		inventoryID="LHW-8028-0102-D496-15BF" # mine
		# inventoryID="LHW-B264-AC0E-0B7D-6BFF" # celui de ma soeur
	else
		if [ $# = 1 ]; then
			inventoryID=$1
		else
			echo "=> $FUNCNAME [inventoryID]" 1>&2
			return 2
		fi
	fi
	\sudo -E \hw-probe -all -upload -i $inventoryID && echo "=> INFO: Check your email to add confirm adding the new node to your inventory : https://linux-hardware.org/index.php?view=computers&inventory=$inventoryID" 1>&2
}

hw_probeAddNodeToInventory "$@"
