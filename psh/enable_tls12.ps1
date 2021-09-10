#
$tls12 = [Enum]::ToObject([System.Net.SecurityProtocolType], 3072)
[System.Net.ServicePointManager]::SecurityProtocol = $tls12
