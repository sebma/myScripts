$dirName = $args[0]
if( ! $dirName ) { $dirName = "." }
$sw = [System.Diagnostics.Stopwatch]::StartNew()

dir $dirName -Force -Recurse -File >$null 2>&1

$sw.Stop()
$duration = $sw.Elapsed
$duration.ToString('hh\:mm\:ss\.ff')
