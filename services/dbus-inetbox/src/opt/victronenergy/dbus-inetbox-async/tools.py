

def set_app_name(name):
  # Fallback to prctl (Linux-only)
  import ctypes
  libc = ctypes.CDLL("libc.so.6")
  libc.prctl(15, name, 0, 0, 0)  # PR_SET_NAME = 15
  

def calculate_checksum(bytestring):
	# The checksum contains the inverted eight bit sum with carry over 
  # all data bytes or all data bytes and the protected identifier.
	cs = 0
	for b in bytestring:
		cs = (cs + b) % 0xFF

	cs = ~cs & 0xFF
	if cs == 0xFF:
		cs = 0
	return cs