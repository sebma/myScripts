$hex = ([string]$args[0]).TrimStart("0x")
$dec = [int]"0x$hex"
echo $dec
