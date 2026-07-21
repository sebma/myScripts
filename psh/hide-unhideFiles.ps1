$scriptName = Split-Path -Leaf $PSCommandPath
function hide-unhideFiles {
        $argc=$args.Count
        $regexp = "."
        if ( $argc -gt 0 ) {
                for($i=0;$i -lt $argc;$i++) {
                        $file = $args[$i]
                        (Get-ItemProperty $file).Attributes = (Get-ItemProperty $file).Attributes -bxor [io.fileattributes]::Hidden
                        "=> Attributes of $file : " + (Get-ItemProperty $file).Attributes
                }
        }
}

hide-unhideFiles @args
