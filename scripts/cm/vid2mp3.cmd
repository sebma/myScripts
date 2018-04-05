@set file=%1
@if not defined file  exit/b 1
@if not exist %file% exit/b 2
@ffmpeg -i %1 2>&1 | findstr /r /i stream.*audio.*mp3 && ffmpeg -i %1 -vn -acodec copy "%~dpn1.mp3" || ffmpeg -i %1 -acodec libmp3lame -ab 160kb -ac 2 -ar 44100 "%~dpn1.mp3"
@for %%f in (%*.mp4 *.flv *.mpg *.mov *.wmv) do (
  ffmpeg -i %%f 2>&1 | findstr /r /i stream.*audio.*mp3 && ffmpeg -i %%f -y -vn -acodec copy "%~dpnf.mp3" || (
    if not exist "%~dpnf.mp3" ffmpeg -i %%f -acodec libmp3lame -ab 160kb -ac 2 -ar 44100 "%~dpnf.mp3"
  )
)
