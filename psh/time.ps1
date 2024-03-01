"=> args = $args"
( Measure-Command { $args | Out-Default } ).ToString()
