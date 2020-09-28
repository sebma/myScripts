@powershell "ls 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' | sort pschildname -descend | select -expand pschildname"
