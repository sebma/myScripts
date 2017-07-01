::@mplayer -dumpaudio -dumpfile "%~dpn1.audio" %1
@ffmpeg -i "%1" -vn -acodec copy "%~dpn1.audio"
