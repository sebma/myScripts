deploy () {
	linuxServerList="deurlx02 deurlx03 heurlx01 heurlx02 heurlx03 heurlx04"
	aixServerList="deur01 heur01 heur02"
	for file
	do
		for server in $linuxServerList
		do
			scp -p $file $server:
		done
	done
}

deploy "$@"
