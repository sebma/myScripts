$dirName = $args[0]
$dirSize = ( dir $dirName -force -recurse | measure -property length -sum ).Sum
if ( $dirSize -gt 1tb ) { "{0:n2} TiB" -f ( $dirSize / 1tb ) }
elseif ( $dirSize -gt 1gb ) { "{0:n2} GiB" -f ( $dirSize / 1gb ) }
elseif ( $dirSize -gt 1mb ) { "{0:n2} MiB" -f ( $dirSize / 1mb ) }
elseif ( $dirSize -gt 1kb ) { "{0:n2} KiB" -f ( $dirSize / 1kb ) }
else { "{0:n2} B" -f ( $dirSize / 1 ) }
