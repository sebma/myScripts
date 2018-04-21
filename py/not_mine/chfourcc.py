#!/usr/bin/env python
import sys

if len(sys.argv) not in (2, 3):
	print """USAGE: %s <filename.avi> [FOURCC]
    Displays old FourCC and optionally changes it to the given new one.""" % (
		sys.argv[0])
	sys.exit(1)

f = file(sys.argv[1], "r+b")

f.seek(0x70)
a = f.read(4)
f.seek(0xbc)
b = f.read(4)
print a, b

if len(sys.argv) > 2:
	newFourCC = sys.argv[2]
	assert len(newFourCC) == 4
	f.seek(0x70)
	f.write(newFourCC)
	f.seek(0xbc)
	f.write(newFourCC)

f.close()
0