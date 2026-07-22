@for %%f in (*.wav) do (
  lame -v --replaygain-accurate "%%f" "%%~nf.mp3" && del "%%f"
)
