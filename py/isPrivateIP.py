#!/usr/bin/env python3

import ipaddress,sys,re
progName = sys.argv[0]
args = sys.argv[1:]
for arg in args :
	if re.search("private",progName,re.IGNORECASE) :
		print( str( ipaddress.ip_address(arg).is_private ) )
	else :
		print( str( not ipaddress.ip_address(arg).is_private ) )
