# NOTE: this is needed for simulation only
# convert a SNES ROM to a 16-bit hex file for $readmemh

import sys
with open(sys.argv[1], 'rb') as rf:
	while True:
		word = rf.read(2)
		if len(word) < 2:
			break
		print("%04x" % (word[1] << 8 | word[0]))
