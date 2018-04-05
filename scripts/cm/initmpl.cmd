@if not exist "P:\mplayer\subfont.ttf" copy %windir%\fonts\arial.ttf "P:\mplayer\subfont.ttf"
@if not exist "%userprofile%\mplayer" mkdir "%userprofile%\mplayer"
@p:\bin\robocopy p:\mplayer "%userprofile%\mplayer" -njh -ndl -nc -ns
