::@mplayer -quiet -nofontconfig -idx -xy 1 -geometry 0%%:93%% %*
@if not exist "%userprofile%\mplayer\subfont.ttf" copy %windir%\fonts\arial.ttf "%userprofile%\mplayer\subfont.ttf
@mplayer -quiet -nofontconfig -idx -xy 1 -geometry 0%%:92%% %*
