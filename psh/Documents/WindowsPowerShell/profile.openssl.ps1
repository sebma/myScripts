if ( $(alias openssl *>$null;$?) ) { del alias:openssl }
Set-Variable -Scope global openssl "${ENV:ProgramData}\scoop\apps\openssl-lts-light\current\bin\openssl.exe"
Set-Alias -Scope Global openssl "${ENV:ProgramData}\scoop\apps\openssl-lts-light\current\bin\openssl.exe"

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

#function viewP12 { openP12 @args | openssl x509 -noout -text; }

#function viewP12Summary { viewP12 @args | sls "CN|Not"; }
