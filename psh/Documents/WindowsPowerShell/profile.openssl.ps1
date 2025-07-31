function setOpenSSLVariables {
	if ( $(alias openssl *>$null;$?) ) { del alias:openssl }
	if( $IsWindows ) {
		Set-Variable -Scope global openssl "${ENV:ProgramData}\scoop\apps\openssl-lts-light\current\bin\openssl.exe"
		Set-Alias -Scope Global openssl "${ENV:ProgramData}\scoop\apps\openssl-lts-light\current\bin\openssl.exe"
	}
}

#setOpenSSLVariables
#"=> openssl = $openssl"

function viewPubKey($pubKey) {
	& $openssl pkey -text -noout -in $pubKey
}

function openCsr {
	& $openssl req -noout -in @args
}

function viewCsr {
	openCsr @args -text
}

function viewCsrSummary {
	openCsr @args -subject -nameopt multiline
}

function openCert {
	& $openssl x509 -notext -noout -in @args
}

function viewCert {
	openCert @args -text
}

function viewCertSummary {
	openCert @args -subject -issuer -dates -ocsp_uri -nameopt multiline
}

function viewFullCert($cert) {
	& $openssl crl2pkcs7 -nocrl -certfile $cert | openssl pkcs7 -noout -text -print_certs
}

function viewFullCertSummary($cert) {
	viewFullCert($cert) | sls "CN|Not"
}

function openP12 {
	& $openssl pkcs12 -nodes -in @args
}

function der2PEM($derFile, $pemFile) {
	& $openssl x509 -in $derFile -outform PEM -out $pemFile
}

function pem2DER($pemFile , $derFile ) {
	& $openssl x509 -in $pemFile -outform DER -out $derFile
}

function pem2P12 ($pemFile, $CAfile , $pemKey , $p12File ) {
	& $openssl pkcs12 -in $pemFile -CAfile $CAfile -inkey $pemKey -export -out $p12File
}

function p12ToPEM($p12File, $pemFile) {
#	$ext = ls $p12File | % Extension
#	$pemFile = $p12File.replace( $ext , ".pem" )
	& $openssl pkcs12 -nodes -in $p12File -out $pemFile
}

function pfx2PEM($pfxFile, $pemFile) {
#	$ext = ls $pfxFile | % Extension
#	$pemFile = $pfxFile.replace( $ext , ".pem" )
	& $openssl pkcs12 -nodes -in $pfxFile -out $pemFile
}

function pfx2PKEY($pfxFile, $pkeyFile) {
#	$ext = ls $pfxFile | % Extension
#	$pemFile = $pfxFile.replace( $ext , ".pem" )
	& $openssl pkcs12 -nocerts -nodes -in $pfxFile -out "$pkeyFile.new"
	& $openssl pkey   -in "$pkeyFile.new" -out $pkeyFile
	remove-item "$pkeyFile.new"
}

function pfxSPLIT() {
	param ($pfxFile)

	$ext = ls $pfxFile | % Extension

	$pwd = Read-Host "Enter Import Password" -AsSecureString
	$env:pwd = [pscredential]::new('dummyusername', $pwd).GetNetworkCredential().Password

	& $openssl pkcs12 -passin env:pwd -nodes -in $pfxFile -out $pfxFile.replace( $ext , "-FULL.pem" )
	& $openssl pkcs12 -passin env:pwd -nocerts -nodes -in $pfxFile -out $pfxFile.replace( $ext , "-PKEY.pem" )
	& $openssl pkcs12 -passin env:pwd -nokeys -clcerts -nodes -in $pfxFile -out $pfxFile.replace( $ext , "-CRT.pem" )
	& $openssl pkcs12 -passin env:pwd -nokeys -cacerts -nodes -in $pfxFile -out $pfxFile.replace( $ext , "-CHAIN.pem" )

#	& $openssl x509 -in "$pemFile.new"  -out $pemFile #To remove the bag attributes
	Remove-Item env:pwd
}

#function viewP12 { openP12 @args | openssl x509 -noout -text; }

#function viewP12Summary { viewP12 @args | sls "CN|Not"; }
function viewPubKey($pubKey) {
	& $openssl pkey -text -noout -in $pubKey
}

function openCsr {
	& $openssl req -noout -in @args
}

function viewCsr {
	openCsr @args -text
}

function viewCsrSummary {
	openCsr @args -subject -nameopt multiline
}

function openCert {
	& $openssl x509 -notext -noout -in @args
}

function viewCert {
	openCert @args -text
}

function viewCertSummary {
	openCert @args -subject -issuer -dates -ocsp_uri -nameopt multiline
}

function viewFullCert($cert) {
	& $openssl crl2pkcs7 -nocrl -certfile $cert | openssl pkcs7 -noout -text -print_certs
}

function viewFullCertSummary($cert) {
	viewFullCert($cert) | sls "CN|Not"
}

function openP12 {
	& $openssl pkcs12 -noenc -in @args
}

function der2PEM($derFile, $pemFile) {
	& $openssl x509 -in $derFile -outform PEM -out $pemFile
}

function pem2DER($pemFile , $derFile ) {
	& $openssl x509 -in $pemFile -outform DER -out $derFile
}

function pem2P12($pemFile, $CAfile, $pemKey , $p12File ) {
	& $openssl pkcs12 -in $pemFile -CAfile $CAfile -inkey $pemKey -export -out $p12File
}

function p12ToPEM($p12File, $pemFile) {
		$ext = ls $p12File | % Extension
		$pemFile = $p12File.replace( $ext , ".pem" )
	& $openssl pkcs12 -noenc -in $p12File -out $pemFile
}

function pfx2PEM($pfxFile, $pemFile) {
		$ext = ls $pfxFile | % Extension
		$pemFile = $pfxFile.replace( $ext , ".pem" )
	& $openssl pkcs12 -noenc -in $pfxFile -out $pemFile
}

function pfx2PKEY($pfxFile, $pkeyFile) {
#	$ext = ls $pfxFile | % Extension
#	$pemFile = $pfxFile.replace( $ext , ".pem" )
	& $openssl pkcs12 -nocerts -nodes -in $pfxFile -out "$pkeyFile.new"
	& $openssl pkey   -in "$pkeyFile.new" -out $pkeyFile
	remove-item "$pkeyFile.new"
}

function viewP12 {
	openP12 @args | openssl x509 -noout -text
}

function viewP12Summary {
	openP12 @args | openssl x509 -noout -subject -issuer -dates -nameopt multiline
}

