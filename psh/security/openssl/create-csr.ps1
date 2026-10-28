$scriptName = Split-Path -Leaf $PSCommandPath
function createSCR {
	$argc=$args.Count
	if ( $argc -lt 2 ) {
		write-warning "Usage:$scriptName csrFileName cnfFileName"
		exit 1
	}

	$csrFileName = $args[0]
	$cnfFileName = $args[1]
	$keyFileName = $csrFileName -replace ".csr" , ".key"

	openssl req -new -keyout $keyFileName -out $csrFileName -config $cnfFileName
	if(Test-Path $csrFileName) {openssl req -in $csrFileName -noout -verify}
}

createSCR @args
