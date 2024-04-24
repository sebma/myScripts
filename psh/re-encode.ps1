$inVideo = $($args[0])
$ext = ls $inVideo | % Extension
$outVideo = $inVideo.replace( $ext , "-SMALLER$ext" )
echo "=> ffmpeg -i $inVideo $outVideo ..."
ffmpeg -i $inVideo $outVideo
