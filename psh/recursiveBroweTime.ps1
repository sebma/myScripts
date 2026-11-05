$dirName = $args[0]
$sw = [System.Diagnostics.Stopwatch]::StartNew();dir $dirName -Force -Recurse -File >$null 2>&1;$sw.Stop();$duration = $sw.Elapsed;$duration.ToString('hh\:mm\:ss\.ff')
