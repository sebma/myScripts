#!/usr/bin/env pwsh
param($filename)
(Get-FileHash -algo SHA384 $filename).Hash + "  " + $filename
