#!/usr/bin/env pwsh
param($filename)
(Get-FileHash -algo MD5 $filename).Hash + "  " + $filename
