#!/usr/bin/env python2
'''
whos.py -- to list objects
By Benyang Tang

execfile('/home/btang/bin/py/whos.py')

CHANGELOG
=========

06/17/2005:  
Now it can list attributes of any objects, not only modules and the global scope.

06/15/2005:  initial version

'''
import string
def whos(module=globals().keys(), what='A', sstr='', casesen=0,  \
  out=0):
#===================================== 
  '''
# Before using whos, do:
execfile('whos.py')

#=== EXAMPLES ===
# to see a list of all objects in the global scope
whos()

# to see a list of functions
whos(what='f')

# to see a list of variables (also their values)
whos(what='v')

# to see a list of Numeric array
whos(what='a')

# to see a list of variables in module os
import os
whos(os, what='v')

# to see a list of all variables of a dictionary
whos({}, what='v')

# to see a list of all functions of a list
whos([], what='f')

# to see a list of variables whose name contains 'path'
whos(what='v', sstr='path')

# to see a list of variables whose name contains 'path' (case insensitive)
whos(what='v', sstr='path', casesen=0)

Argument what can be one of the following:
A -- all
a -- array
f -- function
m -- module
v -- variable

'''
  whosList = 0
  if type(module)==type([]):
    if len(module)>0:
      dirs0 = module
      whosList = 1

  if not whosList:
    temp2 = dir(module)
    dirs0 = map(lambda a: 'module.'+a, temp2)

  type2 = {}
  arrayOk = 1

  if what=='a' or what=='A':
    try: 
      import Numeric as Num
      temp1 =  type(Num.zeros((1,)))
      type2['array'] = temp1
    except:
      arrayOk = 0

    if arrayOk:
      import MA
      temp1 = type(MA.zeros((1,)))
      type2['MA'] = temp1
  
  if what=='a' and not arrayOk:
    print 'Cannot import Numeric'
    return []

  if what=='v' or what=='A':
    temp1 = type(1)
    type2['int'] = temp1

    temp1 = type(1L)
    type2['long'] = temp1

    temp1 = type(1.1)
    type2['float'] = temp1

    temp1 = type('a')
    type2['str'] = temp1

  if what=='f' or what=='A':
    temp1 = type(lambda a: a)
    type2['function'] = temp1

  if what=='m' or what=='A':
    import os
    temp1 = type(os)
    type2['module'] = temp1

  type1 = type2.values()
  dirs0.sort()

  if sstr:
    if casesen:
      p1 = re.compile(sstr)
    else:
      p1 = re.compile(sstr, re.I)

    dirs1 = []
    for d in dirs0:
      if p1.search(d):
        dirs1.append(d)
    dirs0 = dirs1

  collect1 = []
  dirsType = []

  if what=='A':
    for i in range(len(dirs0)): 
      t1 = eval('type('+dirs0[i]+')')
      collect1.append(i)
      dirsType.append(t1)

  else:
    for i in range(len(dirs0)): 
      t1 = eval('type('+dirs0[i]+')')
      #print t1, dirs0[i]
      if t1 in type1:
        collect1.append(i)
        dirsType.append(t1)

  for i in range(len(collect1)):
    ii = collect1[i]
    iType = dirsType[i]
    iType1 = string.split(str(iType), "'")[1]
    if iType1[:2]=="MA":
      iType1 = iType1[:2]
    if iType1[:7]=="builtin":
      iType1 = iType1[:7]

    print '%15s  %15s' %(iType1, string.split(dirs0[ii], '.')[-1]),

    if (what=='a' or what=='A') and arrayOk:
      if iType==type2['MA'] or iType==type2['array']:
        print '%s  %20s  '  %(eval( dirs0[ii]+'.typecode()' ), str( eval( dirs0[ii]+'.shape' ) ) ),
        if iType==type2['MA']:
          print 'unmask=%d of %d'  %(eval(dirs0[ii]+'.count()'),  eval(dirs0[ii]+'.size()') ),

    if what=='v' or what=='A':
      if iType==type2['int'] or iType==type2['long'] or iType==type2['float']:
        print '= ', eval(dirs0[ii]), 
      if iType==type2['str']:
        temp3 = eval(dirs0[ii])
        temp3 = string.replace(temp3, '\n', '\\')
        if len(temp3)<30:
          print '= ', temp3,
        else:
          print '= ', temp3[:30] + ' ...',

    print ''

  if out:
    return [dirs0[i] for i in collect1]
