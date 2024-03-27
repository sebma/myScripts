( "$args" | Measure-Command { Invoke-Expression $_ | Out-Default } ).toString()
