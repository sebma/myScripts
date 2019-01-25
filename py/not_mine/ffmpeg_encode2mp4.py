#!/usr/bin/env python

#
# enc
#
# Version: 1.3.4
# Date:    2013-09-25
# Author:  George Helyar
#

from getopt import getopt, GetoptError
from sys import argv, exit, stderr, platform
from subprocess import Popen, PIPE
from re import search
from datetime import datetime

# Constants
K = 1024
M = 1024 * K
G = 1024 * M

usage = "Usage: enc [-s <size (MiB)> | -t <target media>] [-a <audio bit rate (kbps)>]\n" \
      + "           [-c <audio channels>] [-o <options>] [--ipod=<4x3|16x9>] [-d]\n" \
      + "           [--sim] <file list>"

vcodec = "libx264"
acodec = "libfdk_aac"
pass1preset = ""
pass2preset = ""
#pass1preset = "-vpre fast_firstpass"
#pass2preset = "-vpre slow"
pass1options = "-preset veryfast -x264opts ref=4"
pass2options = "-preset veryfast -x264opts ref=4 -movflags frag_keyframe"

p1out = "/dev/null"
if "win" in platform:
  p1out = "nul"

targets = {
  "quartercd" : (700 / 4) * M,
  "halfcd" : (700 / 2) * M,
  "cd" : 700 * M,
  "dvd" : 4 * G
}

# Functions
def secs(h, m, s):
  return (((h*60)+m)*60)+s

def parse_size(size_string):
  match = search("([\\d\\.]+)\\s*([bkmg]?)", size_string.strip().lower())
  if match == None: return 0

  groups = match.groups()
  fsize = float(groups[0])

  if groups[1] == 'k':
    return int(fsize * K)
  elif groups[1] == 'm':
    return int(fsize * M)
  elif groups[1] == 'g':
    return int(fsize * G)

  return int(fsize)

def calc_audio_size(audio_bitrate, time):
  return (audio_bitrate * 1000 / 8) * time

def calc_video_bitrate(target_bytes, ab, time):
  return (target_bytes - calc_audio_size(ab, time)) / time * 8

def get_duration(file):
#  ffmpeg = Popen("ffmpeg -hide_banner -i " + file, stderr=PIPE, shell=True)
  ffmpeg = Popen(("ffmpeg", "-hide_banner", "-i", file), stderr=PIPE)
  match = search("(\\d+):(\\d+):(\\d+)\\.\\d+", ffmpeg.communicate()[1].decode("utf-8"))
  ffmpeg.stderr.close()

  if match == None: return 0
  dur = match.groups()
  return secs(int(dur[0]), int(dur[1]), int(dur[2]))

def encode(source, dest, opts, vbr, abr=128, ac=2):
  command1 = ("ffmpeg -hide_banner -i \"%s\" -pass 1 -an -vcodec %s %s -b:v %d -bt %d -threads 0"\
    + " %s %s -y -f mp4 \"%s\"") % (source, vcodec, pass1preset, vbr, vbr, opts, pass1options, p1out)

	if acodec = "libfdk_aac" :
		avbr=1
		aprofile="aac_he_v2"
		command2 = ("ffmpeg -hide_banner -i \"%s\" -pass 2 -acodec %s -ac %d -vbr %d -aprofile %s -vcodec %s %s "\
    + "-b:v %d -bt %d -threads 0 %s %s -y \"%s\"") \
    % (source, acodec, ac, avbr, aprofile, vcodec, pass2preset, vbr, vbr, opts, pass2options, dest)
	else :
		command2 = ("ffmpeg -hide_banner -i \"%s\" -pass 2 -acodec %s -ac %d -ab %dk -vcodec %s %s "\
    + "-b:v %d -bt %d -threads 0 %s %s -y \"%s\"") \
    % (source, acodec, ac, abr, vcodec, pass2preset, vbr, vbr, opts, pass2options, dest)

  command3 = "sync"
  commands = [command1, command2, command3]
  
  for command in commands:
    print(command)
    if not sim:
      startTime = datetime.now()
      Popen(command, shell=True).wait()
      print >> stderr, "\n=> The previous command lasted: " + str(datetime.now()-startTime) + "\n"

  print >> stderr, "=> The output file is <" + dest + ">."

# Default settings
target_size = 350 * M
ab = 128 #kbps
ac = 2 #channels
extra_options = ""
ipod_options = ""
sim = False
forced_ab = False

# Parse args
try:
  opts, args = getopt(argv[1:], "hs:a:c:o:t:d",\
    ["help", "size=", "ab=", "ac=", "opts=", "target=", "ipod=", "sim", "deinterlace"])
except GetoptError as err:
  print(str(err))
  exit(2)

for o, a in opts:
  if o in ("-h", "--help"):
    print(usage)
    exit(0)
  elif o in ("-s", "--size"):
    target_size = parse_size(a)
  elif o in ("-t", "--target"):
    target_size = targets[a]
  elif o in ("-a", "--ab"):
    ab = int(a)
    forced_ab = True
  elif o in ("-c", "--ac"):
    ac = int(a)
  elif o in ("-d", "--deinterlace"):
    extra_options = extra_options + ' ' + "-filter:v yadif"
  elif o in ("-o", "--opts"):
    extra_options = extra_options + ' ' + a
  elif o in ("--ipod"):
    a = a.strip().lower()
    ipod_options = " -vpre libx264-ipod320 -s 320x240"
    if a == "16x9":
      ipod_options = ipod_options + " -padtop 30 -padbottom 30 -aspect 4:3"
      
  elif o in ("--sim"):
    sim = True
    

if len(args) < 1:
  print(usage)
  exit(2)

# Loop through files
for file in args:
  duration = get_duration(file)
  if duration <= 0:
    print >> stderr, "Unable to get length of %s" % file
    continue

  # Unless explicitly set
  if not forced_ab:
    # For files over 350m, Mono and Stereo is 192k, Surround is 384k
    if target_size > 350 * M:
      if ac <= 2:
        ab = 192
      else:
        ab = 384

  bitrate = calc_video_bitrate(target_size, ab, duration)
  if bitrate < 1:
    print >> stderr, "%s: A target size of %d bytes is too small, video bitrate would be %s bps." % (file, target_size, bitrate)
    audio_size = calc_audio_size(ab, duration)
    print >> stderr, "  %d seconds of audio at %dk will take %d bytes (%.2f MiB)." % (duration, ab, audio_size, float(audio_size) / M)
    continue

  encode(file, file + ".mp4", extra_options + ipod_options, bitrate, ab, ac)
