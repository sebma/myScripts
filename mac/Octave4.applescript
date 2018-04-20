--
on open argv
 set filename to "\'" & POSIX path of item 1 of argv & "\'"
 do shell script "PATH=/usr/local/bin/:$PATH;cd ~;/usr/local/bin/octave --force-gui --persist --eval \"edit " & filename & "\" | logger 2>&1"
end open
on run
 do shell script "PATH=/usr/local/bin/:$PATH;cd ~;/usr/local/bin/octave --force-gui  | logger 2>&1"
end run
