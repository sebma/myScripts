# vim: ft=powershell noet:

function size2iec {
	$size = $args[0]
	$size2IEC = ""
	switch( $size ) {
		{ $_ -ge 1tb -and $_ -le 1pb } { $size2IEC = "{0:n2} TiB" -f ( $size / 1tb ); break }
		{ $_ -ge 1gb -and $_ -le 1tb } { $size2IEC = "{0:n2} GiB" -f ( $size / 1gb ); break }
		{ $_ -ge 1mb -and $_ -le 1gb } { $size2IEC = "{0:n2} MiB" -f ( $size / 1mb ); break }
		{ $_ -ge 1kb -and $_ -le 1mb } { $size2IEC = "{0:n2} KiB" -f ( $size / 1kb ); break }
		{ $_ -ge 0   -and $_ -le 1kb } { $size2IEC = "{0:n2} B  " -f   $size; break }
	}

	return $size2IEC
}
function dirSize {
	$dirName = $args[0]
 	Write-Host -NoNewline "$dirName`t"
	$dirSize = ( dir "$dirName" -force -recurse | measure -property length -sum ).Sum
 	$dirSize2iec = ( size2iec($size) )
}

function time {
	$duration = ( "$args" | Measure-Command { Invoke-Expression $_ | Out-Default } ).toString("hh\:mm\:ss\.ff")
	echo "`n"$duration"`n"
}

function main {
	$argc = $args.Count
	for($i=0;$i -lt $argc;$i++) {
		$baseDir = $args[$i].TrimEnd('\').TrimEnd('/')
		$subDirsList = $(ls -dir -force $baseDir | % FullName)
		foreach ($subDir in $subDirsList) {
#			( Measure-Command { dirSize $baseDir\$subDir | Out-Default } ).toString("hh\:mm\:ss\.ff")
			time { dirSize $subDir }
		}
	}
}

main @args
