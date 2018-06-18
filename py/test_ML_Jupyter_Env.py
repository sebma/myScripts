#!/usr/bin/env python3

orig_keys = set(globals().keys())

import platform, os, datetime, dateutil

print( "\n=> hostname = <%s>\n" % platform.node() )
print( "=> uname data = <%s>\n" % str(platform.uname() ) )
print( "=> pwd = <%s>\n" % os.getcwd() )
import dateutil.tz # workaround for dateutil bug #770
print( "=> date/time = " + datetime.datetime.now( tz=dateutil.tz.tzlocal() ).strftime('%d/%m/%Y %H:%M:%S %Z %z') )

if   os.environ.get('CONDA_DEFAULT_ENV') :  print( "\n=> CONDA_DEFAULT_ENV = <%s>\n" % os.environ['CONDA_DEFAULT_ENV'] )
elif os.environ.get('VIRTUAL_ENV') :		print( "\n=> VIRTUAL_ENV = <%s>\n" % os.environ['VIRTUAL_ENV'] )

try :
	import matplotlib as mpl
	print( "=> mpl.get_backend() = <%s>\n" % mpl.get_backend() )
finally :	
	from seb_ML import insideCondaEnv
