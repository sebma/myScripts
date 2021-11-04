#!/usr/bin/env pwsh
param($filename)
(Get-FileHash -algo SHA256 $filename).Hash + "  " + $filename
