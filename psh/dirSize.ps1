"{0:n2} MiB" -f ( ( dir $args[0] -force -recurse | measure -property length -sum).Sum /1mb )
