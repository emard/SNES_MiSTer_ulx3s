#!/usr/bin/env bash
set -ex
yosys -q -m ${PLUGIN_DIR}/ghdl.so cxxrtl_sim.ys
g++ ../top/sim_wrapper.cc -o snes_sim -I. -I/usr/local/share/yosys/include -O3
./snes_sim
