function time {
	$duration = ( "$args" | Measure-Command { Invoke-Expression $_ | Out-Default } ).toString("hh\:mm\:ss\.ff")
	echo ""
 	"=> The processing took "+$duration+"."
}

time @args
