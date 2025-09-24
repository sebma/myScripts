$nbLines = 48
if( $args.Count -eq 0 ) { $dirName = "." } else { $dirName = $args[0] }
# " => $dirName = " + $dirName

#dir -Force -r -file $dirName | sort Length -desc | select @{ n= "RelativePath"; e={ Resolve-Path -Relative $_.fullname } } , @{ n="Size"; e={ "{0,5:n3} MiB" -f ($_.length / 1mb) } } | select -f $nbLines
#dir -Force -r -file $dirName | sort Length -desc | select -f $nbLines | select @{ n= "RelativePath"; e={ Resolve-Path -Relative $_.fullname } } , @{ n="Size"; e={ "{0,5:n3} MiB" -f ($_.length / 1mb) } }
#dir -Force -r -file $dirName | ? Length -gt 10mb | select -Property fullName,Length | sort Length -desc | select -f $nbLines | select @{ n= "RelativePath"; e={ Resolve-Path -Relative $_.fullname } } , @{ n="Size"; e={ "{0,5:n3} MiB" -f ($_.length / 1mb) } }

dir -Force -r $dirName 2>$null | ? Length -gt 1mb | select fullname,length | sort Length -desc | select @{ n="Size"; e={ "{0,5:n3} MiB" -f ($_.length / 1mb) } } , @{ n= "RelativePath"; e={ Resolve-Path -Relative $_.fullname } } | select -f $nbLines
