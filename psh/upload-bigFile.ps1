$srcDIR = $HOME+"\Downloads"
$dstDIR = $HOME"+"\Downloads\"+$ENV:USERNAME
$bigFILE = "19041.1.191206-1406.vb_release_CLIENTLANGPACKDVD_OEM_MULTI.iso"

#$robocopyOPTIONS = "/IM"
$robocopyOPTIONS = "/R:0 /W:0 /IM /NP"
$robocopyCOMMAND = "robocopy.exe"
$robocopyARGS = "$srcDIR", "$dstDIR", "$bigFILE" , "/IM" , "/NP"

"=> Copying $srcDIR/$bigFILE $dstDIR  ..."
$cmd = "$robocopyCOMMAND $srcDIR $dstDIR $bigFILE $robocopyOPTIONS"
$duration = Measure-Command { iex $cmd | tee -var result | Out-Default }

"=> The command launched was : "
$cmd
"=> The copy took " + $duration.toString("hh\:mm\:ss\.ff") + " ."

#$speed = cat result.out 2>$null | sls Speed | select -f 1 | % { "{0:n3} MiB" -f ( ($_ -split '\s+')[3]/1MB ) }
$speed = $result | sls Speed | select -f 1 | % { "{0:n3}MiB/s" -f ( ($_ -split '\s+')[3]/1MB ) }

if( $speed ) { "=> Download speed was $speed ." }
if( Test-Path result.out 2>$null ) { rm result.out }
