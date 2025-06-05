$scriptName = Split-Path -Leaf $PSCommandPath
function dcList {
	$argc=$args.Count
	$defaultDomainController = (Get-ADDomainController -Discover).Name
	if ( $argc -eq 0 ) {
		$server = $defaultDomainController
	} elseif ( $argc -eq 1 ) {
		$server = $args[0]
	} else {
		write-warning "Usage:$scriptName [server=$defaultDomainController]"
		exit 1
	}
	Get-ADDomainController -Filter '*' -Server $server | Select Hostname , IPv4Address , OperatingSystem , Site , IsReadOnly | sort Hostname | Format-Table
}

dcList @args
