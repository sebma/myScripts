function time {
	$duration = ( "$args" | Measure-Command { Invoke-Expression $_ | Out-Default } ).toString()
	echo "`n"$duration
}

time @args
