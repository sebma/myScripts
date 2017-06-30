
if os.name == 'posix':
elif os.name == 'nt':

def pid_exists_POSIX(pid):
	"""Check whether pid exists in the current process table."""
	import errno
	if pid < 0:
		return False
	try:
		os.kill(pid, 0)
	except OSError as e:
		return e.errno == errno.EPERM
	else:
		return True

def pid_exists_NT(pid):
	import ctypes
	kernel32 = ctypes.windll.kernel32
	SYNCHRONIZE = 0x100000

	process = kernel32.OpenProcess(SYNCHRONIZE, 0, pid)
	if process != 0:
		kernel32.CloseHandle(process)
		return True
	else:
		return False

