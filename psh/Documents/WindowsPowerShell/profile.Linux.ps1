$USER= $env:USER
$HOSTNAME = $env:HOSTNAME
$global:ls = "ls"
function l1 { & $ls -1F @args }
function la { & $ls -aF @args }
function ll { & $ls -lF @args }
function lla { & $ls -laF @args }
function llah { & $ls -lahF @args }
function lld { & $ls -dlF @args }
function llh { & $ls -lhF @args }
function rm { rm -vi @args }
