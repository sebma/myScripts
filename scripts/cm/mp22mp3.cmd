@for %%f in (*.mp2) do (
  lame -v --replaygain-accurate "%%f" "%%~nf.mp3" && del "%%f"
)
