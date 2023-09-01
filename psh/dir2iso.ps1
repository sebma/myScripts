$scriptName = Split-Path -Leaf $PSCommandPath

function dis2iso {
	$argc=$args.Count
	if ( $argc -ne 2 ) {
		echo "=> Usage $scriptName isoFileName directoryPath"
		exit 1
	}
	$isoFileName = $args[0]
	$directoryPath = $args[1]
	mkisofs -J -R -o $isoFileName $directoryPath
}

dis2iso @args
