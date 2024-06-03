function Prompt {
	$myCMD = $PWD.path
	$myCMD = $myCMD.Replace( $HOME, '~' )
#	$PSHVersion = $PSVersionTable.PSVersion.ToString()
	$PSHVersion = ""+$PSVersionTable.PSVersion.Major + "." + $PSVersionTable.PSVersion.Minor
	if( $isAdmin) { Write-Host "$username : [ " -NoNewline -ForegroundColor Red } else { Write-Host "$username : [ " -NoNewline }
	Write-Host "$hostname " -NoNewline -ForegroundColor Yellow
	Write-Host "@ $domain " -NoNewline -ForegroundColor Red
	#Write-Host "/ $osFamily $OSVersion " -NoNewline -ForegroundColor Green
	Write-Host "] " -NoNewline
	#Write-Host "PSv$PSHVersion " -NoNewline
	Write-Host "PS $myCMD>" -ForegroundColor Green
	if( $isAdmin) { return "# " } else { return "$ " }
}
