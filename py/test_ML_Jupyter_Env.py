#!/usr/bin/env python3

orig_keys = set(globals().keys())

from seb_ML import *

import platform, os, datetime, dateutil

print( "\n=> date/time = " + datetime.datetime.now( tz=dateutil.tz.tzlocal() ).strftime('%d/%m/%Y %H:%M:%S %Z %z') )
print( "\n=> hostname = <%s>" % platform.node() )
print( "\n=> uname data = <%s>" % str(platform.uname() ) )
print( "\n=> pwd = <%s>" % os.getcwd() )
print( "\n=> mpl.get_backend() = <%s>" % mpl.get_backend() )

if   os.environ.get('CONDA_DEFAULT_ENV') :  print( "\n=> CONDA_DEFAULT_ENV = <%s>" % os.environ['CONDA_DEFAULT_ENV'] )
elif os.environ.get('VIRTUAL_ENV') :		print( "\n=> VIRTUAL_ENV = <%s>" % os.environ['VIRTUAL_ENV'] )
