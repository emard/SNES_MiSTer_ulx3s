#!/usr/bin/env bash
set -ex
#yosys -q -m ${PLUGIN_DIR}/ghdl.so synth.ys
yosys -q synth.ys
nextpnr-ecp5 --json snes.json --85k --speed 6 --package CABGA381 --textcfg snes.config --lpf ../top/ulx3s_v20.lpf --no-tmdriv
ecppack --compress snes.config snes.bit
