$scriptName = Split-Path -Leaf $PSCommandPath
function rgrep {
	$argc=$args.Count
	if ( $argc -lt 1 ) {
		write-warning "Usage:$scriptName [dirName=.] regexp"
		exit 1
	}
	if ( $argc -eq 1 ) {
		$dirName = "."
		$regexp = $args[0]
	} elseif ( $argc -eq 1 ) {
		$dirName = $args[0]
		$regexp = $args[1]
	}
	dir -r "$dirName" | sls -list "$regexp"
}

rgrep @args
