# Resolve-DnsName @args
function main {
	$argc = $args.Count
	if ( $argc -eq 0 ) {
		echo USAGE
	} elseif ( $argc -eq 1 ) {
		Resolve-DnsName $args[0]
	} elseif ( $argc -eq 2 ) {
		Resolve-DnsName -name $args[0] -server $args[1]
	} else {
		echo WHATEVER
	}
}

main @args
