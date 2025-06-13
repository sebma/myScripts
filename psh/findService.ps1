$scriptName = Split-Path -Leaf $PSCommandPath
function findService {
	$argc=$args.Count
	$regexp = "."
	if ( $argc -eq 0 ) {
		$regexp = $defaultDomainController
	} elseif ( $argc -eq 1 ) {
		$regexp = $args[0]
	} else {
		write-warning "Usage:$scriptName [regexp=.]"
		exit 1
	}
#	Get-WmiObject win32_service | select Name , DisplayName , ServiceType , StartMode , State , ProcessId , PathName | ogv
	Get-WmiObject win32_service | ? { $_.Description -Match "$regexp" -or $_.Name -Match "$regexp" -or $_.DisplayName -Match "$regexp" } | Format-Table Name , DisplayName , ServiceType , StartMode , State , ProcessId , PathName
}

findService @args
