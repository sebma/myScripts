$USER= $env:USER
$HOSTNAME = $env:HOSTNAME
$global:ls = "ls"
function ll { & $ls -lF @args }
