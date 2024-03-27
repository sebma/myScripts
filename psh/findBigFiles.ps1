# dir -Force -r $dirName | sort Length -desc | select fullname,length @args
$dirName = $args[0]
dir -Force -r $dirName | sort Length -desc | select fullname,length -f 50
