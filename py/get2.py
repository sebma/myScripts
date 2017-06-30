import urllib2
import argparse

def initArgs() :
	parser = argparse.ArgumentParser()
	parser.add_argument("url", help="URL of the remote file to download.")

	global args
	try :    args = parser.parse_args()
	except :
		print >> stderr,  "\n" + parser.format_help()
		exit( -1 )

def myDownload( url, fileName=None ) :
	
	with open(fileName, 'wb') as output: # Note binary mode otherwise you'll corrupt the file
		with urllib2.urlopen(url) as ul:
			CHUNK_SIZE = 8192
			bytes_read = 0
			while True:
				data = ul.read(CHUNK_SIZE)
				bytes_read += len(data) # Update progress bar with this value
				output.write(data)
				if len(data) < CHUNK_SIZE: #EOF
					break

def main() :
	initArgs()
	#download( args.url )
	myDownload( args.url )

main()

