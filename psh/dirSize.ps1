function dirSize {
	$dirName = $args[0]
	$dirSize = ( dir "$dirName" -force -recurse | measure -property length -sum ).Sum
	switch( $dirSize ) {
		{ $_ -ge 1tb -and $_ -le 1pb } { "{0:n2} TiB`t$dirName" -f ( $dirSize / 1tb ); break }
		{ $_ -ge 1gb -and $_ -le 1tb } { "{0:n2} GiB`t$dirName" -f ( $dirSize / 1gb ); break }
		{ $_ -ge 1mb -and $_ -le 1gb } { "{0:n2} MiB`t$dirName" -f ( $dirSize / 1mb ); break }
		{ $_ -ge 1kb -and $_ -le 1mb } { "{0:n2} KiB`t$dirName" -f ( $dirSize / 1kb ); break }
		{ $_ -ge 0   -and $_ -le 1kb } { "{0:n2} B  `t$dirName" -f $dirSize; break }
	}
}

function main {
	$argc = $args.Count
	for($i=0;$i -lt $argc;$i++) {
		$dir = $args[$i]
		echo "=> Size($dir) ..."
		( Measure-Command { dirSize $dir | Out-Default } ).toString()
	}
}

main @args
