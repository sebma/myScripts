function groups {
	$argc=$args.Count
	if ( $argc -eq 0) {
		( (Get-ADUser -Identity $env:username -Properties MemberOf).memberof | Get-ADGroup ).name | sort
	} else {
		for($i=0;$i -lt $argc;$i++) {
			echo "=> Memberships of $($args[$i]) :"
			( ( Get-ADUser -Identity $args[$i] -Properties MemberOf ).memberof | Get-ADGroup ).name | sort
		}
	}
}

groups @args
