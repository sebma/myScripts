#!/usr/bin/env python
#coding: latin1

from __future__ import print_function
import os,sys,platform
import warnings

def osinfo() :
	print()
	print( "=> OS platform.system = " , platform.system() )
	print( "=> OS platform.release = " , platform.release() )
	print( "=> OS platform.processor = " , platform.processor() )
	print( "=> OS platform.architecture = " , platform.architecture() )
	print( "=> OS platform.node = " , platform.node() )
	print( "=> Python version = ", platform.python_version() )
	print( "=> Python interpreter path = ", sys.executable )
	print()
	
	if platform.system() == "Linux" :
		try :
			warnings.simplefilter("error",category=DeprecationWarning)
			print( "=> OS = "  , " ".join( platform.dist() ) )
		except DeprecationWarning :
			import distro
			print( "=> OS = "  , " ".join( distro.linux_distribution() ) )
			warnings.resetwarnings()
	elif platform.system() == "Darwin" :
		print( "=> OS = "  , " ".join( platform.mac_ver() ) )
	elif platform.system() == "Windows" :
		print( "=> OS = "  , " ".join( platform.win32_ver() ) )
		raw_input("Press Enter to continue...")
	
osinfo()

exit(0)
