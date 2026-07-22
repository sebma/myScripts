@move movdump movdump.exe
movdump -i "%1" -o "%~dpn1 - REPAIRED.MOV" -nfd -ref "%2" >> "movdump.txt"
