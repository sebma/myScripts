#!/usr/bin/env python3

orig_keys = set(globals().keys())

import platform, os, datetime, dateutil

print( "\n=> hostname = <%s>" % platform.node() )
print( "\n=> uname data = <%s>" % str(platform.uname() ) )
print( "\n=> pwd = <%s>" % os.getcwd() )
from dateutil import tz # workaround for dateutil bug #770
print( "\n=> date/time = " + datetime.datetime.now( tz=dateutil.tz.tzlocal() ).strftime('%d/%m/%Y %H:%M:%S %Z %z') )

if   os.environ.get('CONDA_DEFAULT_ENV') :  print( "\n=> CONDA_DEFAULT_ENV = <%s>" % os.environ['CONDA_DEFAULT_ENV'] )
elif os.environ.get('VIRTUAL_ENV') :		print( "\n=> VIRTUAL_ENV = <%s>" % os.environ['VIRTUAL_ENV'] )

try :
	import matplotlib as mpl
	print( "\n=> mpl.get_backend() = <%s>" % mpl.get_backend() )
finally :	
	from seb_ML import insideCondaEnv
