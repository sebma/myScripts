#!/usr/bin/env python3

from __future__ import print_function
from pdb import set_trace
import importlib
import os, sys
#print( "=> hostname = " + os.uname().nodename )
print( "=> hostname = " + os.uname()[1] )
for module in [ 'ipdb','IPython','pip','termcolor','jupyter','numpy','matplotlib','networkx','scipy','pandas','pygraphviz','plotly'] :
	try:
		importlib.import_module(module)
		print("==> " + module + " is installed.")
	except Exception as why:
		print(why,file=sys.stderr)
