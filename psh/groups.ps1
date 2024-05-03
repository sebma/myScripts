function groups {
	$DC = Get-ADDomainController 2>$null | % Name
	$DC = $env:LOGONSERVER.Substring(2)
	$argc=$args.Count
	if ( $argc -eq 0) {
		( (Get-ADUser -Identity $env:username -Properties MemberOf).memberof | Get-ADGroup ).name | sort
	} else {
		for($i=0;$i -lt $argc;$i++) {
			echo "=> Memberships of $($args[$i]) :"
			( ( Get-ADUser -Identity $args[$i] -Properties MemberOf -Server $DC ).memberof | Get-ADGroup -Server $DC).name | sort
		}
	}
}

groups @args
