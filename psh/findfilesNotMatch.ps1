function findfilesnotmatch {
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

	dir -r -fo $dirName 2>$null | ? FullName -notmatch "$regexp" | % FullName
}

findfilesnotmatch @args
