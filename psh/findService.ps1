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
	Get-WmiObject win32_service | ? Description -Match "$regexp" | Format-Table Name , DisplayName , Description , PathName , StartMode , Status
}

findService @args
