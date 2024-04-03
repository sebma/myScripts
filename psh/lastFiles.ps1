ls -Force -Dir | ? { ( $_.Name -notLike 'AppData' ) -and ( $_.Name -notLike 'Application Data' ) } | ls -Force -File -R | ? { $_.LastWriteTime -gt (Get-Date).AddMinutes(-5) } | % FullName
