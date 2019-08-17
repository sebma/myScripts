#!/usr/bin/env python
#coding: latin1

from __future__ import print_function
import os,sys
print( os.path.relpath( *( sys.argv[1:] ) ) )
