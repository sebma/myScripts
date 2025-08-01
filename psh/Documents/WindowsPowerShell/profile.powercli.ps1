function diskEnableUUID($vm) {
	if( $vm ) {
		Get-AdvancedSetting -Entity $vm -Name "disk.EnableUUID"
		New-AdvancedSetting -Entity $vm -Name "disk.EnableUUID" -Value "TRUE" -Confirm:$false
		Get-AdvancedSetting -Entity $vm -Name "disk.EnableUUID"
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
function vmInfo($vm) {
	$vm | select Name , PowerState , GuestId , CreateDate , NumCpu , MemoryGB , HardwareVersion , VMHost , Notes
	if( $vm.PowerState -eq "PoweredOn" ) {
		$vm.guest.Nics | select Device , NetworkName , Connected , IPAddress , MacAddress | Format-Table
		$vm.guest.Disks | Format-Table
	}
}

#$vm = Get-VM "Virtual Machine Name"
#Connect-VIServer -Menu
#Disconnect-VIServer -Confirm:$false
