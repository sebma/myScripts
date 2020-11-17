# $HOME/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1
set-alias vi "$env:ProgramFiles/Git/usr/bin/vim.exe"

Import-Alias $HOME/seb_aliases.ps1

Set-Alias rc Edit-PowershellProfile

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

function Edit-PowershellProfile
{
    notepad $Profile
}

function ex{exit}
function cds($p){if($p -eq "-"){popd} else {pushd $p}}
function cdh{pushd $HOME}
function cd-{popd}
function ..{pushd ..}
function ...{pushd ../..}
function ....{pushd ../../..}
function .....{pushd ../../../..}
