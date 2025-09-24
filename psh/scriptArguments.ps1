#!/usr/bin/env pwsh
# param( $firstArg )

"=> outside of main function code block :"
$argc = $args.Length
for ($i=0; $i -lt $argc; $i++) {
	"argv[" + $i + "] = <" + $args[$i] + ">"
}

function main {
	"=> main function code block :"
	$argc = $args.Length
	for ($i=0; $i -lt $argc; $i++) {
		"argv[" + $i + "] = <" + $($args[$i]) + ">"
	}
}

main $args
