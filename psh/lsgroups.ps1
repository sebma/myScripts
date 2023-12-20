function lsgroups {
	$argc=$args.Count
	if ( $argc -gt 0) {
		for($i=0;$i -lt $argc;$i++) {
			echo "=> Members of group $($args[$i]) :"
			(Get-ADGroupMember $($args[$i])).SamAccountName | sort
		}
	}
}

lsgroups @args
