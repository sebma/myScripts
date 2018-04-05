#!/usr/bin/python
 
from getopt import getopt, GetoptError
from sys import argv, exit
 
def secs(h, m, s):
  return (h * 60 + m) * 60 + s
 
def calc_video_bitrate(target_size, abr, time):
  target_bytes = target_size * 1024 * 1024
  audio_bytes = ((abr * 1000) / 8) * time
  return (target_bytes - audio_bytes) / time * 8
 
try:
  opts, args = getopt(argv[1:], "s:a:t:", ["size=", "abr=", "time="])
except GetoptError, err:
  print str(err)
  exit(2)
 
target_size = 350 #MiB
abr = 128 #kbps
time = 0
 
for o, a in opts:
  if o in ("-s", "--size"):
    target_size = int(a)
  elif o in ("-a", "--abr"):
    abr = int(a)
 
if len(args) < 1:
  print "Usage: " + argv[0] + " [-s <size (M)>] [-a <audio bit rate (k)>] [[hh:]mm:]ss"
  exit(2)
 
time_part = args[0].split(":")
if len(time_part) < 2: time_part = [0] + time_part
if len(time_part) < 3: time_part = [0] + time_part
time = secs(int(time_part[0]), int(time_part[1]), int(time_part[2]))
 
print "%d" % calc_video_bitrate(target_size, abr, time)
