function pow2($a,$n) {
	return [math]::pow($a,$n)
}

function time {
	# See https://github.com/lukesampson/psutils/blob/master/time.ps1
	Set-StrictMode -Off;

	# see http://stackoverflow.com/a/3513669/87453
	$cmd, $args = $args
	$args = @($args)
	$sw = [diagnostics.stopwatch]::startnew()
	& $cmd @args
	$sw.stop()

	Write-Warning "$($sw.elapsed)"
}

function findfiles {
	$argc=$args.Count
	if ( $argc -eq 1 ) {
		$dirName = "."
		$regexp = $args[0]
	} elseif ( $argc -eq 2 ) {
		$dirName = $args[0]
		$regexp = $args[1]
	} else {
		write-warning "Usage : [dirName] regexp"
		exit 1
	}

	dir -r -fo $dirName 2>$null | ? FullName -Match "$regexp" | % FullName
}
