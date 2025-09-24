function main {
	$argc = $args.Count
	if ( $argc -eq 0 ) {
		echo USAGE
	} elseif ( $argc -eq 1 ) {
		$fqdn = $args[0] -Replace('https?://|s?ftps?://','') -Replace('/.*$','')
		Resolve-DnsName $fqdn
	} elseif ( $argc -eq 2 ) {
		if ( $args[0] -eq "-4" ) {
			$type = "A"
			$fqdn = $args[1] -Replace('https?://|s?ftps?://','') -Replace('/.*$','')
		} elseif ( $args[0] -eq "-6" ) {
			$type = "AAAA"
			$fqdn = $args[1] -Replace('https?://|s?ftps?://','') -Replace('/.*$','')
			$server = $args[2]
		} else {
			$type = "A_AAAA"
			$fqdn = $args[0] -Replace('https?://|s?ftps?://','') -Replace('/.*$','')
			$server = $args[1]
		}
		Resolve-DnsName -type $type -name $fqdn -server $server
	} else {
		echo WHATEVER
	}
}

main @args
