$dirName = $args[0]
if( ! $dirName ) { $dirName = "." }
$sw = [System.Diagnostics.Stopwatch]::StartNew()

#dir $dirName -Force -Recurse -File -ErrorAction SilentlyContinue >$null
#@(dir $dirName -File -Recurse -Force -ErrorAction SilentlyContinue).Count
(dir $dirName -File -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object).Count

$sw.Stop()
$duration = $sw.Elapsed
$duration.ToString('hh\:mm\:ss\.ff')
