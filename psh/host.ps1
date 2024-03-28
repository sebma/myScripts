function main {
	$argc = $args.Count
	if ( $argc -eq 0 ) {
		echo USAGE
	} elseif ( $argc -eq 1 ) {
		$fqdn = $args[0].TrimStart('https?://').TrimEnd('/.*')
		Resolve-DnsName $fqdn
	} elseif ( $argc -eq 2 ) {
		$fqdn = $args[0].TrimStart('https?://').TrimEnd('/.*')
		$server = $args[1]
		Resolve-DnsName -name $args[0] -server $server
	} else {
		echo WHATEVER
	}
}

main @args
