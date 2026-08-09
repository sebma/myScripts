#!/usr/bin/env pwsh
$nbLines = 48
if( $args.Count -eq 0 ) { $dirName = "." } else { $dirName = $args[0] }
# " => $dirName = " + $dirName
dir -Force -r -file $dirName 2>$null | ? Length -gt 10mb | select Length , FullName | Sort-Object Length -desc | select -f $nbLines | select @{ n="Size"; e={ "{0,5:n3} MiB" -f ($_.length / 1mb) } } , @{ n= "RelativePath"; e={ Resolve-Path -Relative -LiteralPath $_.fullname } }
