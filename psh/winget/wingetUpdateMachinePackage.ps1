write-host "=> winget upgrade --scope machine --id $($args[0]) ..."
winget upgrade --scope machine --id $args[0]
