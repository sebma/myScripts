param($filename)
(Get-FileHash -algo SHA1 $filename).Hash + "  " + $filename
