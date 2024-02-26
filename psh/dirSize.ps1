$dirName = $args[0]
$dirSize = ( dir $dirName -force -recurse | measure -property length -sum ).Sum
"{0:n2} MiB" -f ( $dirSize / 1mb )
"{0:n2} GiB" -f ( $dirSize / 1gb )
"{0:n2} TiB" -f ( $dirSize / 1tb )
