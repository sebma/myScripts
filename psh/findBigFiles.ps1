# dir -Force -r $dirName | sort Length -desc | select fullname,length @args
$dirName = $args[0]
if( $args.Count -eq 0 ) { $dirName = "." }
dir -Force -r -file $dirName | sort Length -desc | select @{ n= "RelativePath"; e={ Resolve-Path -Relative $_.fullname } } , @{ n="Size"; e={ "{0,5:n3} MiB" -f ($_.length / 1mb) } } -f 50
