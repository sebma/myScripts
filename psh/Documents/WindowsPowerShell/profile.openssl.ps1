"=> Sourcing openssl functions ..."
function openCert {
	& $openssl x509 -notext -noout -in @args
}
function openCsr {
	& $openssl req -noout -in @args
}
function openP12 {
	& $openssl pkcs12 -noenc -in @args
}
function p12ToPEM($p12File, $pemFile) {
	& $openssl pkcs12 -nodes -in $p12File -out $pemFile
}
function pem2DER($pemFile , $derFile ) {
	& $openssl x509 -in $pemFile -outform DER -out $derFile
}
function pem2P12($pemFile, $CAfile, $pemKey , $p12File ) {
	& $openssl pkcs12 -in $pemFile -CAfile $CAfile -inkey $pemKey -export -out $p12File
}
function pfx2PEM($pfxFile, $pemFile) {
	& $openssl pkcs12 -nodes -in $pfxFile -out $pemFile
}
function pfx2PKEY($pfxFile, $pkeyFile) {
	& $openssl pkcs12 -nocerts -nodes -in $pfxFile -out "$pkeyFile.new"
	& $openssl pkey   -in "$pkeyFile.new" -out $pkeyFile
	remove-item "$pkeyFile.new"
}
function pfxSPLIT($pfxFile) {
	$ext = ls $pfxFile | % Extension

	$pwd = Read-Host "Enter Import Password" -AsSecureString
	$env:pwd = [pscredential]::new('dummyusername', $pwd).GetNetworkCredential().Password
	Remove-Variable pwd

	& $openssl pkcs12 -passin env:pwd -nocerts -in $pfxFile -nodes -out $pfxFile.replace( $ext , "-PKEY-Bags.pem" )
	& $openssl pkcs12 -passin env:pwd -nokeys -clcerts -in $pfxFile -nodes -out $pfxFile.replace( $ext , "-CRT-Bags.pem" )
	& $openssl pkcs12 -passin env:pwd -nokeys -cacerts -in $pfxFile -nodes -out $pfxFile.replace( $ext , "-CHAIN-Bags.pem" )

	Remove-Item env:pwd

	& $openssl pkey -in $pfxFile.replace( $ext , "-PKEY-Bags.pem" ) -out $pfxFile.replace( $ext , "-PKEY.pem" ) #To remove the bag attributes
	& $openssl x509 -in $pfxFile.replace( $ext , "-CRT-Bags.pem" ) -out $pfxFile.replace( $ext , "-CRT.pem" ) #To remove the bag attributes
	[string[]](& $openssl crl2pkcs7 -nocrl -certfile $pfxFile.replace( $ext , "-CHAIN-Bags.pem" ) | & $openssl pkcs7 -print_certs | sls -n " CN =|^$") | out-file -e utf8 $pfxFile.replace( $ext , "-CHAIN.pem" ) #To remove the bag attributes

	Remove-Item *-Bags.pem
}
function setOpenSSLVariables {
	if ( $(alias openssl *>$null;$?) ) { del alias:openssl }
	if( $IsWindows ) {
		$global:openssl = "${ENV:ProgramData}\scoop\apps\openssl-lts-light\current\bin\openssl.exe"
		Set-Alias -Scope Global openssl "${ENV:ProgramData}\scoop\apps\openssl-lts-light\current\bin\openssl.exe"
	}
}
function viewCert {
	openCert @args -text
}
function viewCertSummary {
	openCert @args -subject -issuer -dates -ocsp_uri -nameopt multiline -ext "subjectAltName,keyUsage,extendedKeyUsage,crlDistributionPoints,authorityInfoAccess"
}
function viewCsr {
	openCsr @args -text
}
function viewCsrSummary {
	openCsr @args -subject -nameopt multiline
}
function viewFullCert($cert) {
	& $openssl crl2pkcs7 -nocrl -certfile $cert | openssl pkcs7 -noout -text -print_certs
}
function viewFullCertSummary($cert) {
	viewFullCert($cert) | sls "CN|Not"
}
function der2PEM($derFile, $pemFile) {
	& $openssl x509 -in $derFile -outform PEM -out $pemFile
}
function viewP12 {
	openP12 @args | openssl x509 -noout -text
}
#function viewP12Summary { viewP12 @args | sls "CN|Not"; }
function viewP12Summary {
	openP12 @args | openssl x509 -noout -subject -issuer -dates -nameopt multiline
}
function viewPubKey($pubKey) {
	& $openssl pkey -text -noout -in $pubKey
}

setOpenSSLVariables
