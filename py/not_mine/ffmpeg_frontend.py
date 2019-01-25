#!/usr/bin/env python
from os.path import isfile, isdir, dirname, abspath, devnull
from os import name, system, sep
from re import findall, sub, match, compile, MULTILINE
from datetime import timedelta
from subprocess import Popen, PIPE, STDOUT
from math import floor, ceil, log
try:
	from multiprocessing import cpu_count
except:
	from psutil import cpu_count

# OS specific strings/commands
if name == 'posix':
	clear, deleteFile = 'clear && clear', 'rm -rf {0}'
elif name == 'nt':
	clear, deleteFile = 'cls', 'del {0} /s /q'

usedFileNames = []
containers = {
	'Copy audio':['mka','mkv'],
	'Copy video':['mkv'],
	'Opus':['opus','webm','ogg','mka','mkv'],
	'Vorbis':['ogg','mka','mkv','mp4','webm'],
	'AAC':['m4a','aac','flv','mka','mkv','mp4','ts','m2ts'],
	'AC3':['ac3','mka','mka','mkv','mp4','ts','m2ts'],
	'MP3':['mp3','mka','mkv','mp4','ts','m2ts','mpg','mpeg','flv'],
	'FLAC':['flac','mka','mkv','mp4','ts','m2ts'],
	'H.264':['mkv','mp4','ts','m2ts','3gp','flv'],
	'H.265':['mkv','mp4','ts','m2ts'],
	'VP8':['mkv','webm'],
	'VP9':['mkv','webm'],
	'MPEG2':['mkv','mp4','ts','m2ts','mpg','mpeg']
}

# Main function
def main():
	global usedFileNames
	jobs = []
	mainMenu1 = [ 'Encode a file', 'Exit without encoding' ]
	mainMenu2 = [ 'Encode a file', 'Delete an entry', 'Start encoding', 'Exit without encoding' ]
	while True:
		listJobs(jobs)
		if len(jobs)==0:
			choice = menu('Main menu:', mainMenu1, index=True)
		else:
			choice = menu('Main menu:', mainMenu2, index=True)
		print('')
		if choice == 0:
			job = { 'inFile' : '"'+getFile('Input file {0}: '.format(len(jobs)+1))+'"' }
			job.update(selectAudio())
			job.update(selectVideo(job))
			if job['vCodec'] or job['aCodec']:
				if yesNo('\nAutomatically name output file?'):
					container = getContainers(job['vCodec'], job['aCodec'])[0]
					job['outFile'] = autoMakeFileName(job['inFile'], container)
				else:
					job['outFile'] = getOutputFile(job)
				job['commands'] = makeCommands(job)
				jobs += [job]
		elif len(jobs):
			if choice == 1:
				i = getInt('Choose an entry to delete: ',1,len(jobs))-1
				usedFileNames.remove(stripX(jobs[i]['outFile']))
				try: usedFileNames.remove(stripX(jobs[i]['statsFile']))
				except: pass
				del jobs[i]
			elif choice == 2:
				listJobs(jobs)
				for i, job in enumerate(jobs):
					print('Encoding file {0}:'.format(i+1))
					runCommands(job['commands'])
					print('')
				jobs, usedFileNames = [], []
				_ = raw_input('Encoding finished. Press Enter to continue...')
			else:
				exit()
		else:
			exit()

# Choose audio codec and options
def selectAudio():
	codec = menu('\nSelect Audio Codec:',['Opus','Vorbis','AAC','AC3','MP3','FLAC','Copy','None'])
	if codec == 'Opus':
		command = '-c:a libopus -b:a {0}k -vbr on -compression_level 10 '.format(getInt('\nAudio Bitrate',32,512))
	elif codec == 'Vorbis':
		command = '-c:a libvorbis -b:a {0}k -q:a 10 '.format(getInt('\nAudio Bitrate',64,384) )
	elif codec == 'AAC':
		command = '-strict -2 -c:a aac -b:a {0}k -vbr 5 '.format(getInt('\nAudio Bitrate',32,320))
	elif codec == 'AC3':
		command = '-c:a ac3 -b:a {0}k '.format(getInt('\nAudio Bitrate',64,384))
	elif codec == 'MP3':
		command = '-c:a libmp3lame -abr 1 -b:a {0}k '.format(getInt('\nAudio Bitrate',32,320))
	elif codec == 'FLAC':
		command = '-c:a flac '
	elif codec == 'Copy':
		command,codec = '-c:a copy ','Copy audio'
	else:
		command,codec = '-an ',None
	return {'aCodec':codec, 'aCommand':command}

# Choose video codec and options
def selectVideo(job):
	codec = menu('\nSelect Video Codec:',['H.264','H.265','VP8','VP9','MPEG2','copy','none'])
	width, statsFile = getResolution(job['inFile'])[0], None
	if codec == 'copy':
		commands,codec,crop = ['-c:v copy '],'Copy video',''
	elif codec == 'none':
		commands,codec,crop = None,None,None
	else:
		statsFile = autoMakeFileName(job['inFile'],'stats')
		if codec == 'H.264':
			commands = h264(statsFile)
		elif codec == 'H.265':
			commands = h265(statsFile)
		elif codec == 'VP8':
			commands = vpx(statsFile,'vp8', width)
		elif codec == 'VP9':
			commands = vpx(statsFile,'vp9', width)
		elif codec == 'MPEG2':
			commands = mpeg2()
		# Choose crop options
		choice = menu('\nCrop video:',['No crop','Auto crop','Manual Crop'])
		if choice == 'No crop':
			crop = ''
		elif choice == 'Auto crop':
			crop = '-vf "{0}" '.format(autoCrop(job['inFile']))
		else:
			crop = '-vf "{0}" '.format(manualCrop(job['inFile']))
	return {'vCommands':commands, 'vCodec':codec, 'crop':crop, 'statsFile':statsFile}

# Make complete set of commands
def makeCommands(job):
	inFile, statsFile, outFile = job['inFile'], job['statsFile'], job['outFile']
	audio, aCodec = job['aCommand'], job['aCodec']
	crop, video = job['crop'], job['vCommands']
	if video == None:
		return ['ffmpeg -i {0} -loglevel error -stats {1}{2}'.format(inFile,audio,outFile)]
	elif len(video) == 1:
		return [
			'ffmpeg -i {0} -loglevel error -stats -c:s copy {1}{2}{3}{4}'.format(inFile,crop,video[0],audio,outFile)
		]
	else:
		commands = [
			'ffmpeg -i {0} -loglevel error -stats -an {1}{2}-f null {3}'.format(inFile,crop,video[0],devnull),
			'ffmpeg -i {0} -loglevel error -stats -c:s copy {1}{2}{3}{4}'.format(inFile,crop,video[1],audio,outFile)
		]
		if job['vCodec'] == 'H.264':
			return commands + [ deleteFile.format(statsFile), deleteFile.format('"'+stripX(statsFile)+'.mbtree"') ]
		elif job['vCodec'] == 'H.265':
			return commands + [ deleteFile.format(statsFile), deleteFile.format('"'+stripX(statsFile)+'.cutree"') ]
		elif job['vCodec'] in ['VP8','VP9']:
			return commands + [ deleteFile.format('"'+stripX(statsFile)+'-0.log"') ]

# Choose x264 options
def h264(statsFile):
	# Preset
	choice = menu(
		'\nSpeed:', ['ultrafast','superfast','veryfast','faster','fast','medium','slow','veryslow','placebo']
	)
	speed = '-preset {0}'.format(choice)
	fastSpeed = '-preset faster' if not choice in ['ultrafast','superfast','veryfast'] else speed
	# Tune
	choice = menu('\nTune for:',['default','film','animation','grain','psnr','ssim','fastdecode'])
	tune = '' if choice=='default' else 'tune={0}:'.format(choice)
	# Bitrate / CRF options
	choice = menu('\nEncoding method:',['CRF','Bitrate'])
	if choice == 'CRF':
		crf = 'crf={0}'.format(getInt('\nCRF value: ',0,50))
		bitrate, passes = '', 1
	else:
		bitrate = 'bitrate={0}'.format(getInt('Bitrate: ',100,40000))
		crf, passes = '', menu('\nNumber of passes:', ['1-Pass','2-Pass'], index=True)+1
	# Commands
	if passes == 1:
		return [ '-c:v libx264 {0} -x264opts {1}{2}{3} '.format(speed,tune,crf,bitrate) ]
	else:
		return [
			'-c:v libx264 {0} -x264opts {1}crf=23:pass=1:stats={2} '.format(fastSpeed,tune,statsFile),
			'-c:v libx264 {0} -x264opts {1}{2}:pass=2:stats={3} '.format(speed,tune,bitrate,statsFile)
		]

# Choose x265 options
def h265(statsFile):
	quiet = 'log-level=error'
	# Preset
	choice = menu(
		'\nSpeed:', ['ultrafast','superfast','veryfast','faster','fast','medium','slow','slower','veryslow','placebo']
	)
	speed = ':preset={0}'.format(choice)
	fastSpeed = ':preset=faster' if not choice in ['ultrafast','superfast','veryfast'] else speed
	# Tune
	choice = menu('\nTune for:',['default','psnr','ssim','grain','fastdecode','zerolatency'])
	tune = '' if choice=='default' else ':tune={0}'.format(choice)
	# Bitrate / CRF options
	choice = menu('\nEncoding method:',['CRF','Bitrate'])
	if choice == 'CRF':
		crf = ':crf={0}'.format(getInt('\nCRF value: ', 0, 51))
		bitrate, passes = '', 1
	else:
		bitrate = ':bitrate={0}'.format(getInt( 'Bitrate: ', 100, 40000 ))
		crf, passes = '', menu('\nNumber of passes:', ['1-Pass','2-Pass'], index=True)+1
	# Commands
	if passes == 1:
		return [ '-c:v libx265 -x265-params {0}{1}{2}{3}{4} '.format(quiet,speed,tune,bitrate,crf) ]
	else:
		return [
			'-c:v libx265 -x265-params {0}{1}{2}:crf=23:pass=1:stats={3} '.format(quiet,fastSpeed,tune,statsFile),
			'-c:v libx265 -x265-params {0}{1}{2}{3}:pass=2:stats={4} '.format(quiet,speed,tune,bitrate,statsFile)
		]

# Choose vpx options
def vpx(statsFile, codec, width):
	cores = min(cpu_count(), int(floor(width/256)))
	tileColumns = int(ceil(log(cores,2)))
	#tileColumns = int(ceil(log(width)/log(2)-8))
	threads = '-tile-columns {0} -t {1}'.format(tileColumns, cores)
	# Speed
	choice = getInt('\nSpeed (-16 to 16): ', -16, 16)
	speed = ' -speed {0}'.format(choice)
	fastSpeed = ' -speed {0}'.format(16) if choice>13 else ' -speed {0}'.format(choice+3)
	# Bitrate / CRF options
	choice = menu('\nEncoding method:',['CRF','Bitrate'])
	if choice == 'CRF':
		crf = ' -crf {0}'.format( getInt('\nCRF value: ',-1,63) )
		bitrate, passes = ' -b:v 0', 1
	else:
		bitrate = ' -b:v {0}K'.format(getInt('Bitrate: ',100,40000))
		crf, passes = '', menu('\nNumber of passes:',['1-Pass','2-Pass'], index=True)+1
	# Commands
	if passes == 1:
		return [ '-c:v {0} {1}{2}{3}{4} '.format(codec,threads,speed,bitrate,crf) ]
	else:
		return [
			'-c:v {0} {1}{2} -crf 20 -pass 1 -passlogfile {3} '.format(codec,threads,fastSpeed,statsFile),
			'-c:v {0} {1}{2}{3} -pass 2 -passlogfile {4} '.format(codec,threads,speed,bitrate,statsFile)
		]

# Choose mpeg2 options.
def mpeg2():
	choice = menu('\nEncoding method:',['Quality','Bitrate'])
	if choice=='Quality':
		quality = '-qscale:v {0}'.format(getInt('Quality (1 to 31 - lower is better): ',1,31))
		bitrate = ''
	else:
		bitrate = '-b:v {0}k'.format(getInt('Bitrate: ',100,40000))
		quality = ''
	return [ '-c:v mpeg2video {0}{1}'.format(bitrate,quality) ]

# Get video resolution
def getResolution(inFile):
	command = 'ffprobe -v error -show_entries stream=width,height -of default=noprint_wrappers=1 {0}'.format(inFile)
	output = Popen(command,stdout=PIPE,shell=True).communicate()[0].replace('\r','')
	return [
		int(findall('(?<=width\=)\d+', output, MULTILINE)[0]),
		int(findall('(?<=height\=)\d+', output, MULTILINE)[0])
	]

#Get video/audio duration in seconds
def getDuration(inFile):
	command = 'ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1 {0}'.format(inFile)
	output = Popen(command,stdout=PIPE,shell=True).communicate()[0].replace('\r','')
	return float(findall('(?<=duration\=)[\d.]+', output, MULTILINE)[0])

# Manually specify crop dimensions
def manualCrop(inFile):
	print('')
	width, height = getResolution(inFile)
	print('Video resolution is {0}x{1}'.format(width, height))
	top = getInt('Top: ',0,height)
	bottom = getInt('Bottom: ',0,height-top)
	left = getInt('Left: ',0,width)
	right = getInt('Right: ',0,width-left)
	return 'crop={0}:{1}:{2}:{3}'.format(width-left-right, height-top-bottom, left, top)

# Automatically detect and crop black bars
def autoCrop(inFile):
	duration = int(floor(getDuration(inFile)))
	start = timedelta(seconds=duration/3) # must be formatted to H:MM:SS
	length = 20 if duration > 35 else duration/2
	command =\
		'ffmpeg -i {0} -ss {1} -t {2} -vf "cropdetect=24:2:0" -f null {3} 2>&1'.format(inFile,start,length,devnull)
	output = Popen(command,stdout=PIPE,shell=True).communicate()[0].replace('\r','')
	crop = findall('crop\=\d+:\d+:\d+:\d+', output, MULTILINE)
	if len(crop):
		return max(set(crop), key=crop.count) # return the most frequently suggested value
	else:
		width, height = getResolution(inFile)
		return 'crop={0}:{1}:0:0'.format(width,height) # zero cropping if a crop value can't be found

# Clear screen and list job queue
def listJobs(jobs):
	system(clear)
	print('Encode queue:')
	for i, job in enumerate(jobs):
		if (job['vCodec']!=None) ^ (job['aCodec']!=None):
			print(' {0}. {1} -> {2}'.format(i+1, job['inFile'], job['vCodec'] or job['aCodec']))
		else:
			print(' {0}. {1} -> {2} + {3}'.format(i+1, job['inFile'], job['vCodec'], job['aCodec']))
	if not len(jobs):
		print(' None yet')
	print('')

# Run a list of commands, print output in real time.
def runCommands(commands):
	for command in commands:
		print(command)
		try:
			process = Popen(command, stdout=PIPE, bufsize=1, shell=True)
			for line in iter(process.stdout.readline, b''):
				print(line.strip('\r\n'))
			process.stdout.close()
			process.wait()
		except OSError as e:
			print(str(e))

# Get a list of containers compatible with selected codecs
def getContainers(vCodec, aCodec):
	global containers
	if vCodec!=None:
		if aCodec!=None:
			return [x for x in containers[vCodec] if x in containers[aCodec]]
		else:
			return containers[vCodec]
	else:
		return containers[aCodec]

# Delete leading/trailing spaces/tabs, then quotation marks
def stripX(file):
	return sub('(^["\']*|["\']*$)', '', sub('(^[\t\s]*|[\t\s]*$)', '', file))

# Ask user to enter a file name, make sure it exists (or doesn't, if new=True). Optionally check against a regex.
def getFile(question, new=None, regex=None, error=None):
	while True:
		answer = stripX(raw_input(question))
		if regex!=None:
			if match(regex, answer) is None:
				print(error or 'Invalid file name')
				continue
		if new==True:
			global usedFileNames
			if isfile(answer) or answer in usedFileNames:
				print('File already exists')
			elif not isdir(dirname(abspath(answer))):
				print('Directory doesn\'t exist')
			else:
				usedFileNames += [answer]
				return answer
		elif new==None or new==False:
			if isfile(answer):
				return answer
			print('File doesn\'t exist')

# Get output file name
def getOutputFile(job):
	global usedFileNames
	validContainers = getContainers(job['vCodec'], job['aCodec'])
	originalPath = dirname(stripX(job['inFile']))+sep
	print('Compatible containers: '+', '.join(validContainers))
	while True:
		answer = stripX(raw_input('Output file: '))
		# If no path specified, make output path the same as the original file
		if dirname(answer)=='':
			answer = originalPath+answer
		if match('.+({0})$'.format('|'.join(valid)), answer) is None:
			print('Invalid or incompatible container/extension specified.')
		elif isfile(answer) or answer in usedFileNames:
			print('File already exists')
		elif not isdir(dirname(abspath(answer))):
			print('Directory doesn\'t exist')
		else:
			usedFileNames += [answer]
			return '"'+answer+'"'

# Create new file name by replacing the file extension of input file
def autoMakeFileName(inFile, ext):
	global usedFileNames
	outFile = sub( '\.[A-Za-z0-9]+$', '.{0}'.format(ext), stripX(inFile))
	i = 2
	# If a file with the new file name already exists, append a number to it
	while True:
		if not isfile(outFile) and outFile not in usedFileNames:
			break
		outFile = sub( '\.[A-Za-z0-9]+$', '_{0}.{1}'.format(i,ext), stripX(inFile))
		i += 1
	usedFileNames += [outFile]
	return '"'+outFile+'"'

# Ask for an integer, make sure it falls between min and max.
def getInt(question, min, max):
	min,max = [int(max),int(min)] if min>max else [int(min),int(max)]
	while True:
		try:
			answer = int(raw_input('{0}: '.format(question)))
			if min <= answer <= max:
				return answer
			print('Must be a number from {0} to {1}'.format(min,max))
		except ValueError:
			print('Not a valid number')

# Ask a yes/no question, return True or False
def yesNo(question):
	while True:
		answer = raw_input(question+' (y/n): ')
		if match('^[Yy](|[Ee][Ss])$',answer):
			return True
		elif match('^[Nn](|[Oo])$',answer):
			return False

# Print a menu from a list, get user selection, return the item string (or index number, if index=True)
def menu(title, items, index=None):
	print(title)
	for i, item in enumerate(items):
		print('{0}. {1}'.format(i+1, item))
	answer = getInt('', 1, len(items)) - 1
	return answer if index==True else items[answer]

# Execute main function
main()
