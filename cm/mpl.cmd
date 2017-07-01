::p:\mplayer\mplayer -quiet -nofontconfig -idx -xy 1 -geometry 0%%:92%% %* 2>nul | findstr "stream VIDEO AUDIO"
@p:\mplayer\mplayer2 -v -idx -xy 1 -geometry 0%%:92%% %* 2>nul | grep -E "stream [0-9].*:|VIDEO:|AUDIO:|^MPEG|^A:"
