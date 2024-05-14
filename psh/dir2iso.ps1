$scriptName = Split-Path -Leaf $PSCommandPath
$scriptDIR = $PSScriptRoot
$scriptPath  = $PSCommandPath
function dis2iso {
	$argc=$args.Count
	if ( $argc -ne 2 ) {
		write-warning "Usage:$scriptName isoFileName directoryPath"
		exit 1
	}
	$isoFileName = $args[0]
	$directoryPath = $args[1].TrimEnd('\')
	mkisofs -J -R -o $isoFileName $directoryPath
}

dis2iso @args
