# $HOME/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1
Import-Alias $HOME/seb_aliases.ps1
Set-Alias vi "$env:ProgramFiles/Git/usr/bin/vim.exe"
Set-Alias  ex

function Prompt
{
    $mywd = (pwd).Path
    $mywd = $mywd.Replace( $HOME, '~' )
#    $PSHVersion = $PSVersionTable.PSVersion.ToString()
    $PSHVersion = [String]$PSVersionTable.PSVersion.Major + "." + $PSVersionTable.PSVersion.Minor
    Write-Host "PSv$PSHVersion " -NoNewline -ForegroundColor DarkGreen
    Write-Host ("" + $mywd + ">") -NoNewline -ForegroundColor Green
    return " "
}

function ex{exit}
function cds($p){if($p -eq "-"){popd} else {pushd $p}}
function cdh{pushd $HOME}
function cd-{popd}
function ..{pushd ..}
function ...{pushd ../..}
function ....{pushd ../../..}
function .....{pushd ../../../..}
