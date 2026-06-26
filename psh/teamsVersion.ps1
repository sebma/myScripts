'MSTeams' , 'MicrosoftTeams' | % { (Get-AppxPackage $_).Version }
