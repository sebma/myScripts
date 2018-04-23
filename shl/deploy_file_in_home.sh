deploy () {
	linuxServerList="pingoin01 pingoin02"
	aixServerList="toto01 toto02"
	for file
	do
		for server in $linuxServerList
		do
			scp -p $file $server:
		done
	done
}

deploy "$@"
