# vim: set ft=sh noet:
Set-PSDebug -Trace 1
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
# 
New-Item -Path $Profile -ItemType file -Force
