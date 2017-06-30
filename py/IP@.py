#!/usr/bin/env python
#coding: latin1
from socket import gethostname, gethostbyname
print gethostbyname( gethostname() )
#raw_input("Press Enter to continue...")
