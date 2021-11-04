#!/usr/bin/env pwsh
param($filename)
(Get-FileHash -algo SHA512 $filename).Hash + "  " + $filename
