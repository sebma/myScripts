$scriptName = Split-Path -Leaf $PSCommandPath
function dcList {
	$argc=$args.Count
	if ( $argc -eq 0 ) {
		$server = (Get-ADDomainController -Discover).Name
	} else if ( $argc -eq 1 ) {
		$server = $args[0]
	} else {
		write-warning "Usage:$scriptName [dirName=.]"
		exit 1
	}
	Get-ADDomainController -Filter '*' -Server $server | Select Hostname , IPv4Address , OperatingSystem , Site , IsReadOnly | sort Hostname | Format-Table
}

dcList @args
