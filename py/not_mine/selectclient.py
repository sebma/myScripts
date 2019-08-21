#!/usr/bin/env python

__author__  = 'Nathan Farrar'
__email__   = 'nathan.farrar@gmail.com'
__website__ = 'http://www.oxseyn.com/'
__version__ = 0.1

import optparse
import select
import sys
import telnetlib

def main():
	""" This is a simple conceptual example of a working asynchronous telnet
	client written in python.  It is not very robust.  Telnetlib does not handle
	telnet command codes correctly.  Telnetlib also does not handle exceptions
	correctly.  I think the proper way to impliment this would be to write my
	own telnet module that wraps a raw socket. """

	usage = "./asyncclient .py -h host_name -p port_number"

	parser = optparse.OptionParser(usage=usage)
	parser.add_option("-a", "--address", dest="address", default="localhost")
	parser.add_option("-p", "--port", dest="port", default=23)

	(options,args) = parser.parse_args()

	size = 4096

	running = False

	""" Telnetlib is broken.  You cannot catch the error if the statement fails.
	Hence, the error checking I perform on the raw socket. """

	try:
		session = telnetlib.Telnet(options.address, options.port)
	except:
		print 'telnetlib error: could not connect to ', options.address, ' ', options.port
	else:
		skt = session.get_socket()
		running = True

		""" input is a tuple used by select.  It contains a list of all the sources of
		data. """
		input = [skt, sys.stdin]

		while running:

			""" Asynchronous network programming requires the elimination of
			blocking methods in code.  In this example, we use the select module to
			poll the socket and stdin before attmepting to read from either. """

			input_ready, output_ready, except_ready = select.select(input, [], [])

			for input_source in input_ready:

				if input_source == skt:

					while session.sock_avail():
						try:
							data = session.read_some()
							if data:
								sys.stdout.write(data)
							else:
								""" This is a hack to detecting when the distant end
								has closed the connection.  When the connection has
								been closed, telnetlib.read_some() will be true, be
								return nothing.  When we read_some() but get nothing
								we stop the main loop with running = False and then
								break out of the sock_avail() loop. """
								running = False
								break;
						except:
							print 'except on session.read_some()'

				elif input_source == sys.stdin:
					try:
						session.write(sys.stdin.readline())
					except:
						print 'except on session.write()'

			""" If we receive a line from telnet server that does not end with \r\n,
			it gets stuck in the stdout buffer.  By calling sys.stdout.flush() at
			the end of every loop, we dump things like prompts to the console.  """

			sys.stdout.flush()

		session.close()

if __name__ == '__main__':
	main()