function diskEnableUUID($vm) {
	$today = $(Get-Date -f 'yyyyMMdd')
	if( $vm ) {
		$parameter = "disk.EnableUUID"
		echo "=> Taking Snapshot before setting `"$parameter = TRUE`" ..."
		New-Snapshot -VM $vm -Name Before.disk.EnableUUID-$today -Memory:$true -Description "Before setting `"$parameter = TRUE`"."
		echo "=> Done"
		echo "=> Before :"
		Get-AdvancedSetting -Entity $vm -Name $parameter | select Name , Value | ft
		New-AdvancedSetting -Entity $vm -Name $parameter -Value "TRUE" -Confirm:$false
		echo "=> After :"
		Get-AdvancedSetting -Entity $vm -Name $parameter | select Name , Value | ft
		echo "=> FINISHED."
	}
}
function enableCopyPaste($vm) {
	$today = $(Get-Date -f 'yyyyMMdd')
	if( $vm ) {
		echo "=> Taking Snapshot before enabling copy/paste ..."
		New-Snapshot -VM $vm -Name Before-Enable-Copy-Paste-$today -Description "Before enabling copy/paste." -Memory:$true
		echo "=> Done"
		$parameter = "isolation.tools.copy.disable"
		echo "=> Before :"
		Get-AdvancedSetting -Entity $vm -Name $parameter | select Name , Value | ft
		New-AdvancedSetting -Entity $vm -Name $parameter -Value "FALSE" -Confirm:$false
		echo "=> After :"
		Get-AdvancedSetting -Entity $vm -Name $parameter | select Name , Value | ft
		$parameter = "isolation.tools.paste.disable"
		echo "=> Before :"
		Get-AdvancedSetting -Entity $vm -Name $parameter | select Name , Value | ft
		New-AdvancedSetting -Entity $vm -Name $parameter -Value "FALSE" -Confirm:$false
		echo "=> After :"
		Get-AdvancedSetting -Entity $vm -Name $parameter | select Name , Value | ft
		$parameter = "isolation.tools.setGUIOptions.enable"
		echo "=> Before :"
		Get-AdvancedSetting -Entity $vm -Name $parameter | select Name , Value | ft
		New-AdvancedSetting -Entity $vm -Name $parameter -Value "TRUE" -Confirm:$false
		echo "=> After :"
		Get-AdvancedSetting -Entity $vm -Name $parameter | select Name , Value | ft
		echo "=> FINISHED."
	}
}
function enableVMXNET3($vm) {
	if( $vm ) {
		$nic = Get-NetworkAdapter -VM $vm
		$nic
		Set-NetworkAdapter -NetworkAdapter $nic -Type "vmxnet3" -Confirm:$false
		$nic
	}
}
function listVMinVLAN {
	if( "$vlan" ) {
		Get-VM | where { $(Get-NetworkAdapter -VM $_).NetworkName -eq "$vlan" }
	}
}
function vmInfo($vm) {
	if( $vm ) {
		$vm | select Name , PowerState , GuestId , CreateDate , NumCpu , MemoryGB , HardwareVersion , VMHost , Notes
		if( $vm.PowerState -eq "PoweredOn" ) {
			$vm.guest.Nics | select Device , NetworkName , Connected , IPAddress , MacAddress | Format-Table
   			Get-NetworkAdapter $vm | select Name , Type , NetworkName , WakeOnLanEnabled
			$vm.guest.Disks | Format-Table
		}
	}
}

#$vm = Get-VM "Virtual Machine Name"
#Connect-VIServer -Menu
#Disconnect-VIServer -Confirm:$false
