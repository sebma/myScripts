$argc = $args.Count
function getlaps {
	$DC = $env:LOGONSERVER.Substring(2)
	$argc=$args.Count
	if ( $argc -gt 0) {
		for($i=0;$i -lt $argc;$i++) {
			$PC = $args[$i]
			echo "=> LAPS of $PC :"
			$(Get-ADComputer $PC -Properties ms-Mcs-AdmPwd)."ms-Mcs-AdmPwd"
		}
	}
}

getlaps @args
