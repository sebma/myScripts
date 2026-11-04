$dirName = $args[0]
$sw = [System.Diagnostics.Stopwatch]::StartNew(); dir $dirName -Force -Recurse -File 2>$null | % Name >$null;$sw.Stop();$duration = $sw.Elapsed;$duration.ToString('hh\:mm\:ss\.ff')
