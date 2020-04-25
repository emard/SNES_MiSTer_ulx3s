# For simulation
# convert a CSV format frame to PNG

from PIL import Image
import sys

width = 0

lines = []

with open(sys.argv[1]) as csvf:
	for line in csvf:
		sl = line.strip().split(",")
		width = max(width, len(sl))
		line = []
		for pixel in sl:
			if len(pixel) == 0:
				continue
			r, g, b = pixel.split("|")
			line.append((int(r[2:], 16), int(g[2:], 16), int(b[2:], 16)))
		lines.append(line)

img = Image.new("RGB", (width, len(lines)))

for y, line in enumerate(lines):
	for x, p in enumerate(line):
		img.putpixel((x, y), p)

img.save(sys.argv[2])
