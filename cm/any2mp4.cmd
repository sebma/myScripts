@echo off
set fileList=%1
if not defined fileList (
  echo =^> Usage: %0 ^<fileList pattern^> >&2
  exit/b 1
)

ver | find "Version 6" && set ffmpegDIR=%programfiles(x86)%\winff || set ffmpegDIR=%programfiles%\winff

for %%f in (%fileList%) do @(
  echo.
  echo File=%%f
  "%ffmpegDIR%\ffmpeg" -i "%%f" 2>&1 | find "Video: h264" && (
    echo.
    echo File=%%f contains mp4 video.
    "%ffmpegDIR%\ffmpeg" -i "%%f" -f mp4 -vcodec copy -acodec copy "%%~dpnf.mp4"
    del "%%f" && echo =^> "%%f" file is deleted.
  )
)
