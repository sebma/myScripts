function dirSize {
	$dirName = $args[0]
	# $dirSize = [uint64]( ( dir "$dirName" -force -recurse | measure -property length -sum ).Sum )
	$dirSize = ( dir "$dirName" -force -recurse | measure -property length -sum ).Sum
	switch( $dirSize ) {
		{ $_ -ge 1tb -and $_ -le 1pb } { "{0:n2} TiB" -f ( $dirSize / 1tb ); break }
		{ $_ -ge 1gb -and $_ -le 1tb } { "{0:n2} GiB" -f ( $dirSize / 1gb ); break }
		{ $_ -ge 1mb -and $_ -le 1gb } { "{0:n2} MiB" -f ( $dirSize / 1mb ); break }
		{ $_ -ge 1kb -and $_ -le 1mb } { "{0:n2} KiB" -f ( $dirSize / 1kb ); break }
		{ $_ -ge 0   -and $_ -le 1kb } { "{0:n2} B" -f $dirSize; break }
	}
}

$argc = $args.Count
for($i=0;$i -lt $argc;$i++) {
	$dir = $args[$i]
	echo "=> Size($dir) ..."
	dirSize $dir
}
