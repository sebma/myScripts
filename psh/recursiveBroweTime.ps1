$dirName = $args[0]
if( ! $dirName ) { $dirName = "." }
$sw = [System.Diagnostics.Stopwatch]::StartNew()

#dir $dirName -Force -Recurse -File >$null 2>&1
(dir $dirName -File -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object).Count
#@(dir $dirName -File -Recurse -Force -ErrorAction SilentlyContinue).Count

$sw.Stop()
$duration = $sw.Elapsed
$duration.ToString('hh\:mm\:ss\.ff')
