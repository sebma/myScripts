#!/usr/bin/env python3

orig_keys = set(globals().keys())

from seb_ML import *

import platform, os, datetime, dateutil

print( datetime.datetime.now( tz=dateutil.tz.tzlocal() ).strftime('%d/%m/%Y %H:%M:%S %Z %z') )
print( "\n=> hostname = " + platform.node() )
print( "\n=> uname Data = " +  str(platform.uname() ) )
print( "\n=> pwd = " + os.getcwd() )
print( "\n=> CONDA_DEFAULT_ENV = "+os.environ['CONDA_DEFAULT_ENV'] )
