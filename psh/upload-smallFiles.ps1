$dirSep = [io.path]::DirectorySeparatorChar
$dir2COPY = "myDIR"
$srcDIR = $HOME + $dirSep + "Downloads" + $dirSep + $dir2COPY
$dstDIR = $srcDIR + $dirSep + ".." + $ENV:USERNAME + $dirSep + $dir2COPY

#$robocopyOPTIONS = "/E /IM /NFL"
$robocopyOPTIONS = "/E /R:0 /W:0 /IM /IS /IT /NFL /NP"
$robocopyCOMMAND = "robocopy.exe"
#$robocopyARGS = "$srcDIR", "$dstDIR" , "/IM" , "/NP"

"=> Copying $srcDIR $dstDIR  ..."
$cmd = "$robocopyCOMMAND $srcDIR $dstDIR $robocopyOPTIONS"
$duration = Measure-Command { iex $cmd | tee -var result | Out-Default }

"=> The command launched was : "
$cmd
"=> The copy took " + $duration.toString("hh\:mm\:ss\.ff") + " ."

#$speed = cat result.out 2>$null | sls Speed | select -f 1 | % { "{0:n3} MiB" -f ( ($_ -split '\s+')[3]/1MB ) }
$speed = $result | sls Speed | select -f 1 | % { "{0:n3}MiB/s" -f ( ($_ -split '\s+')[3]/1MB ) }

#$result
if( $speed ) { "=> Download speed was $speed ." }
if( Test-Path result.out 2>$null ) { rm result.out }
