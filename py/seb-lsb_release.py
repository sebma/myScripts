#!/usr/bin/env python3
#coding: latin1

from __future__ import print_function
import distro

print( distro.lsb_release_info()['distributor_id'] )
print( distro.lsb_release_info()['description'] )
print( distro.lsb_release_info()['release'] )
print( distro.lsb_release_info()['codename'] )
