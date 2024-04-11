$srcDIR = $HOME+"\Downloads"
$dstDIR = $HOME"+"\Downloads\"+$ENV:USERNAME
$bigFILE = "19041.1.191206-1406.vb_release_CLIENTLANGPACKDVD_OEM_MULTI.iso"

#$robocopyOPTIONS = "/IM"
$robocopyOPTIONS = "/R:0 /W:0 /IM /NP"
$robocopyCOMMAND = "robocopy.exe"
$robocopyARGS = "$srcDIR", "$dstDIR", "$bigFILE" , "/IM" , "/NP"
"=> $robocopyARGS = "+$robocopyARGS

"=> Copying $srcDIR/$bigFILE $dstDIR  ..."
"=> robocopy $srcDIR $dstDIR $bigFILE $robocopyOPTIONS"
#$result = robocopy $srcDIR $dstDIR $bigFILE $robocopyOPTIONS
#$speed = $result | sls Speed | select -f 1 | % { "{0:n3} MiB" -f ( ($_ -split '\s+')[3]/1MB ) }

#Measure-Command { iex $_ | Out-Default } ).toString()
#& $robocopyCOMMAND $robocopyARGS | tee result.out
$cmd = "$robocopyCOMMAND $srcDIR $dstDIR $bigFILE $robocopyOPTIONS"
"=> cmd = "+$cmd
#iex $cmd | tee result.out
#( Measure-Command { iex $cmd | Out-Default } ).toString()

"=> The copy took " + ( Measure-Command { iex $cmd | tee -var result | Out-Default } ).toString("hh\:mm\:ss\:ff") + "."

#$speed = cat result.out 2>$null | sls Speed | select -f 1 | % { "{0:n3} MiB" -f ( ($_ -split '\s+')[3]/1MB ) }
$speed = $result | sls Speed | select -f 1 | % { "{0:n3} MiB/s" -f ( ($_ -split '\s+')[3]/1MB ) }

#$result
if( $speed ) { "=> Download speed was $speed." }
if ( Test-Path result.out 2>$null ) { rm result.out }
