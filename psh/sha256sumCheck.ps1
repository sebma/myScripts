$scriptName = Split-Path -Leaf $PSCommandPath

function times {
	# See https://github.com/lukesampson/psutils/blob/master/time.ps1
	Set-StrictMode -Off;

	# see http://stackoverflow.com/a/3513669/87453
	$cmd, $args = $args
	$args = @($args)
	$sw = [diagnostics.stopwatch]::startnew()
	& $cmd @args
	$sw.stop()

#	Write-Warning "$($sw.elapsed)"
	[Console]::Error.WriteLine( "$($sw.elapsed)" )
}

function sha256sum {
	$argc = $args.Count
	if ( $argc -ne 1 ) {
		write-warning "=> Usage : $scriptName checkSumFile"
		exit 1
	}

	$checkSumFile = $args[0]
	if( ! (Test-Path $checkSumFile) ) {
		$host.ui.WriteErrorLine("=> [ERROR] $checkSumFile does not exists.")
		exit 2
	}

	$algorithm = $($scriptName -replace "sum.*","")
	$nbLines = $(cat $checkSumFile).Count
	$i = 0
	$failed = $false
	times cat $checkSumFile | foreach {
			$checkSum = ($_ -split '\s+')[0]
			$file = ($_ -split '\s+')[1]
			$trueCheckSum = $(Get-FileHash -a $algorithm $file).hash.Tolower()
			if( $trueCheckSum -eq $checkSum ) { echo "$file : OK" } else { $failed = $true;++$i; echo "$file : FAILED" }
		}
	if( $failed ) { [Console]::Error.WriteLine( "$scriptName : WARNING: $i of $nbLines computed checksums did NOT match" ) }
}

sha256sum @args
