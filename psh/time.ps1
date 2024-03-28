function time {
        ( "$args" | Measure-Command { Invoke-Expression $_ | Out-Default } ).toString()
}

time @args
