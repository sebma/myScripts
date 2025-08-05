function diskEnableUUID($vm) {
	if( $vm ) {
		echo "=> Taking Snapshot before setting `"disk.EnableUUID = TRUE`" ..."
		New-Snapshot -VM $vm -Name Before.disk.EnableUUID -Memory $true -Description "Before setting `"disk.EnableUUID = TRUE`"."
		echo "=> Done"
		echo "=> Before :"
		Get-AdvancedSetting -Entity $vm -Name "disk.EnableUUID"
		New-AdvancedSetting -Entity $vm -Name "disk.EnableUUID" -Value "TRUE" -Confirm:$false
		echo "=> After :"
		Get-AdvancedSetting -Entity $vm -Name "disk.EnableUUID"
		echo "=> FINISHED."
	}
}
function enableCopyPaste($vm) {
	$today = $(Get-Date -f 'yyyyMMdd')
	if( $vm ) {
		echo "=> Taking Snapshot before enabling copy/paste ..."
		New-Snapshot -VM $vm -Name Before.disk.EnableUUID-$today -Memory $true -Description "Before enabling copy/paste."
		echo "=> Done"
		foreach( $parameter in "isolation.tools.copy.enable" , "isolation.tools.paste.enable" , "isolation.tools.setGUIOptions.enable" ) {
			echo "=> Before :"
			Get-AdvancedSetting -Entity $vm -Name "$parameter"
			New-AdvancedSetting -Entity $vm -Name "$parameter" -Value "TRUE" -Confirm:$false
			echo "=> After :"
			Get-AdvancedSetting -Entity $vm -Name "$parameter"
		}
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
