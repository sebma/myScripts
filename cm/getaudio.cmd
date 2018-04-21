::@mplayer -dumpaudio -dumpfile "%~dpn1.audio" %1
@echo off
set file=%1
if not defined file (
  echo =^> Usage: %0 ^<filename^>
  exit/b 1
)
if not exist %file% (
  echo =^> ERROR: The file ^<%1^> does not exist.
  exit/b 2
)

ffmpeg -i %1 2>&1 | findstr /r /i stream.*audio.*mp3 && ffmpeg -i %1 -vn -acodec copy "%~dpn1.mp3"
ffmpeg -i %1 2>&1 | findstr /r /i stream.*audio.*aac && ffmpeg -i %1 -vn -acodec copy "%~dpn1.aac"
ffmpeg -i %1 2>&1 | findstr /r /i stream.*audio.*vorbis && ffmpeg -i %1 -vn -acodec copy "%~dpn1.ogg"
