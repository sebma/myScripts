$dirName = $args[0]
"{0:n2} MiB" -f ( ( dir $dirName -force -recurse | measure -property length -sum).Sum /1mb )
