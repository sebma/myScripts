function lsgroup {
	$DC = $env:LOGONSERVER.Substring(2)
	$argc=$args.Count
	if ( $argc -gt 0) {
		for($i=0;$i -lt $argc;$i++) {
  			$group = $args[$i]
			echo "=> Members of group $group :"
			Get-ADGroupMember $group -server $DC | SamAccountName | sort
		}
	}
}

lsgroup @args
